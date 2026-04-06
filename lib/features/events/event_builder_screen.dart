import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/conversion_event.dart';
import '../tracking/tracking_provider.dart';

/// Predefined event types the user can fire from the UI.
enum _EventType {
  purchase('Purchase'),
  addToCart('AddToCart'),
  viewContent('ViewContent'),
  completeRegistration('CompleteRegistration'),
  subscribe('Subscribe'),
  search('Search');

  const _EventType(this.label);
  final String label;
}

class EventBuilderScreen extends ConsumerStatefulWidget {
  const EventBuilderScreen({super.key});

  @override
  ConsumerState<EventBuilderScreen> createState() =>
      _EventBuilderScreenState();
}

class _EventBuilderScreenState extends ConsumerState<EventBuilderScreen> {
  _EventType _selectedType = _EventType.purchase;
  final _valueController = TextEditingController(text: '9.99');
  final _currencyController = TextEditingController(text: 'USD');
  final _contentIdController = TextEditingController(text: 'sku_12345');
  bool _isSending = false;

  @override
  void dispose() {
    _valueController.dispose();
    _currencyController.dispose();
    _contentIdController.dispose();
    super.dispose();
  }

  Future<void> _fireEvent() async {
    setState(() => _isSending = true);

    final manager = ref.read(analyticsManagerProvider);
    final value = double.tryParse(_valueController.text);
    final currency = _currencyController.text.trim();
    final contentId = _contentIdController.text.trim();

    final conversion = ConversionEvent(
      eventName: _selectedType.label,
      value: value,
      currency: currency.isNotEmpty ? currency : null,
      contentType: 'product',
      contentId: contentId.isNotEmpty ? contentId : null,
    );

    switch (_selectedType) {
      case _EventType.purchase:
        await manager.logPurchase(conversion);
      case _EventType.addToCart:
      case _EventType.viewContent:
      case _EventType.completeRegistration:
        await manager.logConversion(conversion);
      case _EventType.subscribe:
      case _EventType.search:
        await manager.logEvent(
          name: _selectedType.label,
          parameters: conversion.toParameters(),
        );
    }

    ref.read(eventHistoryProvider.notifier).refresh();

    if (mounted) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedType.label} event sent'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Builder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Event type selector ----
          Text('Event Type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<_EventType>(
            showSelectedIcon: false,
            segments: _EventType.values
                .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                .toList(),
            selected: {_selectedType},
            onSelectionChanged: (v) =>
                setState(() => _selectedType = v.first),
            multiSelectionEnabled: false,
          ),
          const SizedBox(height: 24),

          // ---- Parameters ----
          Text('Parameters', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),

          TextField(
            controller: _valueController,
            decoration: const InputDecoration(
              labelText: 'Value',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _currencyController,
            decoration: const InputDecoration(
              labelText: 'Currency',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_exchange),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _contentIdController,
            decoration: const InputDecoration(
              labelText: 'Content ID',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 32),

          // ---- Fire button ----
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _isSending ? null : _fireEvent,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSending
                    ? 'Sending...'
                    : 'Fire ${_selectedType.label} Event',
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info card
          Card(
            color: Colors.blue.withValues(alpha: 0.05),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Events are dispatched to both Meta SDK and '
                      'Firebase Analytics simultaneously. Disable '
                      'consent in Settings to block sending.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
