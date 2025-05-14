import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/domain/entities/occupancy_record.dart';
import 'package:smartgymai/providers/sensors_provider.dart';

// Provider for Gemini API response
final geminiResponseProvider = StateProvider<String?>((ref) => null);
final geminiLoadingProvider = StateProvider<bool>((ref) => false);
final geminiErrorProvider = StateProvider<String?>((ref) => null);

class AIAnalyticsScreen extends ConsumerStatefulWidget {
  const AIAnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIAnalyticsScreen> createState() => _AIAnalyticsScreenState();
}

class _AIAnalyticsScreenState extends ConsumerState<AIAnalyticsScreen> {
  static const String _apiKey = 'AIzaSyCF6LA-J24iOr8LAln7EkLBkdpKvDDY0QA';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.0-flash';

  @override
  void initState() {
    super.initState();
    // Load sensor data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sensorsProvider.notifier).fetchOccupancyHistory(days: 7);
    });
  }

  Future<void> analyzeData() async {
    ref.read(geminiLoadingProvider.notifier).state = true;
    ref.read(geminiErrorProvider.notifier).state = null;
    ref.read(geminiResponseProvider.notifier).state = null;
    
    try {
      // Get the sensor history for the past week
      final occupancyData = ref.read(sensorsProvider).occupancyHistory;
      
      if (occupancyData.isEmpty) {
        ref.read(geminiErrorProvider.notifier).state = 'No data available for analysis';
        ref.read(geminiLoadingProvider.notifier).state = false;
        return;
      }
      
      // Format occupancy and sensor data for analysis
      final formattedData = _formatDataForGemini(occupancyData);
      
      // Make the API request to Gemini
      final response = await _callGeminiAPI(formattedData);
      
      ref.read(geminiResponseProvider.notifier).state = response;
    } catch (e) {
      ref.read(geminiErrorProvider.notifier).state = 'Error analyzing data: $e';
    } finally {
      ref.read(geminiLoadingProvider.notifier).state = false;
    }
  }
  
  String _formatDataForGemini(List<OccupancyRecord> records) {
    // Group by date and calculate daily statistics
    final Map<String, List<OccupancyRecord>> dailyRecords = {};
    
    for (final record in records) {
      final dateStr = DateFormat('yyyy-MM-dd').format(record.timestamp);
      if (!dailyRecords.containsKey(dateStr)) {
        dailyRecords[dateStr] = [];
      }
      dailyRecords[dateStr]!.add(record);
    }
    
    // Format data as a prompt for Gemini
    final StringBuffer prompt = StringBuffer();
    prompt.write('Analyze the following gym sensor data for the past week:\n\n');
    
    // Sort dates
    final sortedDates = dailyRecords.keys.toList()..sort();
    
    for (final date in sortedDates) {
      final dayRecords = dailyRecords[date]!;
      
      // Calculate daily averages
      double avgTemp = 0;
      double avgHumidity = 0;
      double avgLight = 0;
      double avgOccupancy = 0;
      int validTempCount = 0;
      int validHumidityCount = 0;
      int validLightCount = 0;
      
      for (final record in dayRecords) {
        // Add occupancy count
        avgOccupancy += record.count;
        
        // Extract sensor readings if available
        if (record.sensorReadings != null) {
          if (record.sensorReadings!['temperature'] != null) {
            avgTemp += record.sensorReadings!['temperature'];
            validTempCount++;
          }
          if (record.sensorReadings!['humidity'] != null) {
            avgHumidity += record.sensorReadings!['humidity'];
            validHumidityCount++;
          }
          if (record.sensorReadings!['light'] != null) {
            avgLight += record.sensorReadings!['light'].toDouble();
            validLightCount++;
          }
        }
      }
      
      // Calculate averages
      if (validTempCount > 0) avgTemp /= validTempCount;
      if (validHumidityCount > 0) avgHumidity /= validHumidityCount;
      if (validLightCount > 0) avgLight /= validLightCount;
      avgOccupancy /= dayRecords.length;
      
      // Add to prompt
      prompt.write('Date: $date\n');
      prompt.write('Average Occupancy: ${avgOccupancy.toStringAsFixed(1)} people\n');
      if (validTempCount > 0) prompt.write('Average Temperature: ${avgTemp.toStringAsFixed(1)}°C\n');
      if (validHumidityCount > 0) prompt.write('Average Humidity: ${avgHumidity.toStringAsFixed(1)}%\n');
      if (validLightCount > 0) prompt.write('Average Light: ${avgLight.toStringAsFixed(1)} lux\n');
      prompt.write('\n');
    }
    
    prompt.write('\nPlease analyze this data and provide insights on:\n');
    prompt.write('1. Occupancy patterns throughout the week\n');
    prompt.write('2. Correlations between environmental factors (temperature, humidity, light) and gym occupancy\n');
    prompt.write('3. Recommendations for optimal gym operations based on these patterns\n');
    prompt.write('4. Predictions for next week\'s occupancy based on these trends\n');
    
    return prompt.toString();
  }
  
  Future<String> _callGeminiAPI(String prompt) async {
    final url = Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey');
    
    final payload = {
      'contents': [
        {
          'parts': [
            {
              'text': prompt
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      }
    };
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    
    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      return responseBody['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Failed to call Gemini API: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorsState = ref.watch(sensorsProvider);
    final geminiResponse = ref.watch(geminiResponseProvider);
    final isLoading = ref.watch(geminiLoadingProvider);
    final error = ref.watch(geminiErrorProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(sensorsProvider.notifier).fetchOccupancyHistory(days: 7);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(sensorsProvider.notifier).fetchOccupancyHistory(days: 7);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'AI Gym Analytics',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Analyze your gym\'s sensor data using Google\'s Gemini AI. '
                        'The analysis includes occupancy patterns, environmental correlations, '
                        'and recommendations for optimal operations.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      if (sensorsState.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (sensorsState.errorMessage != null)
                        Center(
                          child: Text(
                            'Error loading data: ${sensorsState.errorMessage}',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        )
                      else if (sensorsState.occupancyHistory.isEmpty)
                        const Center(
                          child: Text('No occupancy data available for the past week'),
                        )
                      else
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: analyzeData,
                            icon: const Icon(Icons.lightbulb_outline),
                            label: const Text('Generate AI Analysis'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing data with Gemini AI...'),
                    ],
                  ),
                )
              else if (error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Analysis Error',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (geminiResponse != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.light_mode, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'AI Analysis Results',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          geminiResponse,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
