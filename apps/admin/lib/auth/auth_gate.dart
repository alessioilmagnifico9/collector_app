import 'dart:async';

import 'package:flutter/material.dart';

import 'researcher_auth.dart';

class ResearcherAuthGate extends StatefulWidget {
  final ResearcherAuth? auth;
  final WidgetBuilder home;
  const ResearcherAuthGate({super.key, required this.auth, required this.home});
  @override
  State<ResearcherAuthGate> createState() => _ResearcherAuthGateState();
}

class _ResearcherAuthGateState extends State<ResearcherAuthGate> {
  final email = TextEditingController(), password = TextEditingController();
  StreamSubscription<bool>? subscription;
  bool signedIn = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    signedIn = widget.auth?.signedIn ?? false;
    subscription = widget.auth?.changes.listen((value) {
      if (mounted)
        setState(() {
          signedIn = value;
          error = null;
        });
    });
  }

  @override
  void dispose() {
    unawaited(subscription?.cancel());
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> authenticate() async {
    if (busy || widget.auth == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (signedIn) {
        await widget.auth!.signOut();
      } else {
        await widget.auth!.signIn(email.text, password.text);
      }
      if (mounted) setState(() => signedIn = widget.auth!.signedIn);
    } catch (_) {
      if (mounted)
        setState(
          () => error = 'Sign-in could not be updated. Check your details and connection.',
        );
    } finally {
      password.clear();
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Research Console'),
      actions: [
        if (signedIn)
          TextButton(
            onPressed: busy ? null : authenticate,
            child: const Text('Sign out'),
          ),
      ],
    ),
    body: SafeArea(
      child: signedIn
          ? widget.home(context)
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Researcher sign-in',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (widget.auth == null)
                        const Text(
                          'Connect your research service using the setup instructions before signing in.',
                        ),
                      if (error != null)
                        Semantics(liveRegion: true, child: Text(error!)),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          labelText: 'Researcher email',
                        ),
                      ),
                      TextField(
                        controller: password,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        onSubmitted: (_) => unawaited(authenticate()),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: busy || widget.auth == null
                            ? null
                            : authenticate,
                        child: Text(busy ? 'Signing in…' : 'Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    ),
  );
}
