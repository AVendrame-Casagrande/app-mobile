import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/translator.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// Modulo Profilo / Login — porting di www/scripts/Profilo.
class ProfiloPage extends StatefulWidget {
  const ProfiloPage({super.key});

  @override
  State<ProfiloPage> createState() => _ProfiloPageState();
}

class _ProfiloPageState extends State<ProfiloPage> {
  bool _busy = false;

  String _t(String s) => Translator.translate(s);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final utente = app.utenteLoggato;
    final logged = app.isLogged;

    return Scaffold(
      appBar: AppBar(title: Text(_t('Profilo'))),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAccountCard(context, app),
              const SizedBox(height: 16),
              if (logged) ...[
                _sectionTitle(_t('INFO ACCOUNT')),
                _infoRow(_t('Nome'), utente.nomeUtente),
                _infoRow(_t('TIPO ACCOUNT'), _t(utente.accountType)),
                if (utente.emailUtente.isNotEmpty)
                  _infoRow('Email', utente.emailUtente),
                if (utente.nomePortale.isNotEmpty)
                  _infoRow('Portale', utente.nomePortale),
                const SizedBox(height: 16),
              ],
              _sectionTitle('Opzioni'),
              if (utente.language == 'I') ...[
                SwitchListTile(
                  title: const Text('Ricerca Vocale'),
                  value: app.ricercaVocaleActive,
                  activeColor: AppColors.toggleOn,
                  onChanged: (v) => app.setRicercaVocale(v),
                ),
                SwitchListTile(
                  title: const Text('Highlight'),
                  value: app.highlightActive,
                  activeColor: AppColors.toggleOn,
                  onChanged: (v) => app.setHighlight(v),
                ),
                SwitchListTile(
                  title: const Text('Notifiche Casagrande Group'),
                  value: app.casagrandeGroupNotificationsActive,
                  activeColor: AppColors.toggleOn,
                  onChanged: (v) => app.setGroupNotifications(v),
                ),
              ],
            ],
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.spinner),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, AppState app) {
    final logged = app.isLogged;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.casagrandeDark,
          child: Text(
            logged ? '🚪' : '🔑',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          logged ? app.utenteLoggato.nomeUtente : 'Ospite',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          logged
              ? _t('Vuoi effettuare il Logout da questo Account?')
              : _t('Inserisci il tuo Codice Utente per effettuare il Login'),
        ),
        trailing: ElevatedButton(
          onPressed: logged ? () => _confirmLogout(app) : () => _startLogin(app),
          child: Text(logged ? _t('Logout') : _t('Login')),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.casagrandeDark,
          ),
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(color: Colors.black54)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  // -------------------------------------------------------------------------
  // Flusso di Login: codice utente -> password -> verifica.
  // -------------------------------------------------------------------------
  Future<void> _startLogin(AppState app) async {
    final codice = await _askText(
      title: _t('ID Utente'),
      hint: _t('Inserisci il tuo Codice Utente per effettuare il Login'),
    );
    if (codice == null || codice.trim().isEmpty) return;

    final password = await _askText(
      title: _t('Password'),
      hint: _t('Inserisci la tua Password'),
      obscure: true,
    );
    if (password == null || password.isEmpty) return;

    setState(() => _busy = true);
    final result = await app.login(codice, password);
    setState(() => _busy = false);

    switch (result) {
      case LoginResult.success:
        if (!mounted) return;
        _alert(
          '${_t('Login Effettuato con Successo! Ciao')} ${app.utenteLoggato.nomeUtente}',
          title: _t('Credenziali Corrette'),
        );
        break;
      case LoginResult.wrongCredentials:
        _alert(_t('ID Utente o Password Errati'), title: _t('Credenziali Errate'));
        break;
      case LoginResult.networkError:
        _alert(_t('Errore di Rete durante il Login'));
        break;
    }
  }

  Future<void> _confirmLogout(AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Logout')),
        content: Text(_t('Vuoi effettuare il Logout da questo Account?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('Chiudi')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('Logout')),
          ),
        ],
      ),
    );
    if (ok == true) {
      final nome = app.utenteLoggato.nomeUtente;
      await app.logout();
      if (!mounted) return;
      _alert('${_t('Logout effettuato con Successo. Non sei più loggato come')} $nome');
    }
  }

  // -------------------------------------------------------------------------
  // Helper UI.
  // -------------------------------------------------------------------------
  Future<String?> _askText({
    required String title,
    String? hint,
    bool obscure = false,
  }) {
    final controller = TextEditingController();
    bool obscured = obscure;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: obscured,
            textCapitalization:
                obscure ? TextCapitalization.none : TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: obscure
                  ? IconButton(
                      icon: Icon(
                          obscured ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setLocal(() => obscured = !obscured),
                    )
                  : null,
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t('Chiudi')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(_t('Conferma')),
            ),
          ],
        ),
      ),
    );
  }

  void _alert(String message, {String? title}) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('Chiudi')),
          ),
        ],
      ),
    );
  }
}
