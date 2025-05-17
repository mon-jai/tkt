import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/parking_lot_model.dart';
import '../services/parking_lot_service.dart';

class ParkingLotScreen extends StatefulWidget {
  const ParkingLotScreen({super.key});

  @override
  State<ParkingLotScreen> createState() => _ParkingLotScreenState();
}

class _ParkingLotScreenState extends State<ParkingLotScreen> {
  final ParkingLotService _parkingLotService = ParkingLotService();
  List<ParkingLot> _parkingLots = [];
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadParkingLots();
  }

  Future<void> _loadParkingLots() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final parkingLots = await _parkingLotService.getAllParkingLots();
      if (mounted) {
        setState(() {
          _parkingLots = parkingLots;
          _isLoading = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getLastUpdatedText() {
    if (_lastUpdated == null) return '';
    return '更新時間：${DateFormat('HH:mm:ss').format(_lastUpdated!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('機車停車位查詢'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadParkingLots,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _parkingLots.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在獲取停車場資訊...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadParkingLots,
              icon: const Icon(Icons.refresh),
              label: const Text('重試'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_lastUpdated != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _getLastUpdatedText(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadParkingLots,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _parkingLots.length,
              itemBuilder: (context, index) {
                final parkingLot = _parkingLots[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: parkingLot.isFull ? Colors.red : Colors.green,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_parking, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  parkingLot.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: parkingLot.isFull
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      parkingLot.isFull
                                          ? Icons.error_outline
                                          : Icons.check_circle_outline,
                                      size: 16,
                                      color: parkingLot.isFull
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      parkingLot.isFull ? '已滿' : '有空位',
                                      style: TextStyle(
                                        color: parkingLot.isFull
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.two_wheeler, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                '機車車位：',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                parkingLot.availabilityText,
                                style: TextStyle(
                                  color: parkingLot.isFull
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
} 