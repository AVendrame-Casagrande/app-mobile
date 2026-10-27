import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/i18n/translator.dart';
import '../../core/theme/app_theme.dart';
import '../../models/version_info.dart';
import '../../state/app_state.dart';
import 'aggiorna_service.dart';

/// Pagina Aggiorna — porting di www/scripts/Aggiorna.
/// Confronta la versione corrente con l'ultima sul server, mostra il
/// change log e permette di scaricare il nuovo APK.
class AggiornaPage extends StatefulWidget {
  const AggiornaPage({super.key});

  @override
  State<AggiornaPage> createState() => _AggiornaPageState();
}

class _AggiornaPageState extends State<AggiornaPage> {
  late final AggiornaService _service;

  bool _loading = true;
  String? _error;
  VersionInfo? _info;

  final String _currentVersion = AppConfig.webClientVersion;

  @override
  void initState() {
    super.initState();
    _service = AggiornaService(context.read<AppState>().api);
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await _service.checkVersion();
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = Translator.translate('Errore di Connessione');
        _loading = false;
      });
    }
  }

  Future<void> _downloadUpdate() async {
    final uri = Uri.parse(_service.apkDownloadUrl());
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(Translator.translate('Errore di Connessione'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translator.translate('Aggiornamento')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _check,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.spinner));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _check, child: Text(Translator.translate('Riprova'))),
          ],
        ),
      );
    }

    final info = _info!;
    final updateAvailable =
        _service.isUpdateAvailable(_currentVersion, info);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Icon(
            updateAvailable ? Icons.system_update : Icons.check_circle,
            size: 72,
            color: updateAvailable ? AppColors.casagrande : Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            updateAvailable
                ? Translator.translate('È disponibile una nuova Versione')
                : Translator.translate(
                    "Applicazione già Aggiornata all'ultima Versione"),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _versionRow(Translator.translate('Versione attuale'),
                    'v$_currentVersion'),
                const Divider(),
                _versionRow(
                    Translator.translate('Ultima versione'), 'v${info.code}'),
                if (info.mandatoryUpdate) ...[
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(Translator.translate(
                            'Aggiornamento Obbligatorio')),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (info.changeLog.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Change Log (v${info.code})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...info.changeLog.map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(line)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (updateAvailable)
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: Text(Translator.translate('Aggiorna')),
            onPressed: _downloadUpdate,
          ),
      ],
    );
  }

  Widget _versionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
