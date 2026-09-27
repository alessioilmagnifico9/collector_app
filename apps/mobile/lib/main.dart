import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:experiment_models/experiment_models.dart';

import 'collection/controller.dart';
import 'collection/bootstrap.dart';
import 'enrollment/qr_scan.dart';
import 'collection/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const demo = bool.fromEnvironment('COLLECTOR_DEMO');
  final gateway = demo
      ? DemoEnrollmentGateway(
          asJson(
            jsonDecode(
              await rootBundle.loadString(
                '../../protocols/example_protocol.json',
              ),
            ),
          ),
        )
      : UnconfiguredEnrollmentGateway();
  CollectionController controller;
  if (demo) {
    controller = CollectionController(
      enrollmentGateway: gateway,
      capture: DemoTrialCapture(),
      demo: true,
    );
  } else {
    try {
      controller = await createLocalCollector();
    } catch (_) {
      controller = CollectionController(
        enrollmentGateway: UnconfiguredEnrollmentGateway(),
        capture: UnconfiguredTrialCapture(),
      )..error = 'This phone could not prepare recording. Please contact your researcher.';
    }
  }
  runApp(CollectorApp(controller: controller));
}

class CollectorApp extends StatelessWidget {
  final CollectionController? controller;
  const CollectorApp({super.key, this.controller});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Dataset Collector',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xff176b60),
      useMaterial3: true,
    ),
    home: CollectionScreen(controller: controller),
  );
}

class CollectionScreen extends StatefulWidget {
  final CollectionController? controller;
  const CollectionScreen({super.key, this.controller});
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with WidgetsBindingObserver {
  late final CollectionController flow;
  final code = TextEditingController();
  @override
  void initState() {
    super.initState();
    flow =
        widget.controller ??
        CollectionController(
          enrollmentGateway: UnconfiguredEnrollmentGateway(),
          capture: UnconfiguredTrialCapture(),
        );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    flow.setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached)
      unawaited(flow.interrupt());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    code.dispose();
    flow.dispose();
    super.dispose();
  }

  Future<void> openStudy() async {
    await flow.enroll(code.text);
    if (mounted && flow.enrollment != null) code.clear();
  }

  Widget button(String label, VoidCallback? action) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: FilledButton(
      onPressed: action,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      child: Text(label),
    ),
  );
  Widget title(String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(value, style: Theme.of(context).textTheme.headlineMedium),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: flow,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Dataset Collector')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (flow.demo)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Demonstration • no research data is collected. Use DEMO2026.',
                        ),
                      ),
                    ),
                  if (flow.error != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        flow.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ...content(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  List<Widget> content() {
    switch (flow.page) {
      case CollectionPage.enrollment:
        return [
          title('Welcome'),
          const Text(
            'Enter the participant code or enrollment link provided by your researcher.',
          ),
          TextField(
            controller: code,
            decoration: const InputDecoration(
              labelText: 'Participant code or enrollment link',
            ),
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => unawaited(openStudy()),
          ),
          if (flow.canResume)
            button(
              'Continue saved study',
              flow.busy ? null : () => unawaited(flow.enroll('')),
            ),
          button(
            'Scan study QR code',
            flow.busy
                ? null
                : () async {
                    final result = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) => const EnrollmentScanner(),
                      ),
                    );
                    if (result != null && mounted) {
                      code.text = result;
                      await openStudy();
                    }
                  },
          ),
          button(
            flow.busy ? 'Opening study…' : 'Open study',
            flow.busy ? null : () => unawaited(openStudy()),
          ),
        ];
      case CollectionPage.overview:
        return [
          title(flow.enrollment!.study.name),
          const Text('Choose a session to begin.'),
          TextButton(
            onPressed: flow.busy ? null : flow.changeParticipant,
            child: const Text('Change participant'),
          ),
          if (flow.canResume)
            TextButton(
              onPressed: flow.busy
                  ? null
                  : () => unawaited(flow.refreshStudy()),
              child: const Text('Refresh study instructions'),
            ),
          for (final session in flow.availableSessions) ...[
            if (session.instructions != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(session.instructions!),
              ),
            button(
              session.title,
              flow.busy ? null : () => unawaited(flow.selectSession(session)),
            ),
          ],
        ];
      case CollectionPage.instructions:
        final plan = flow.current;
        return [
          Text('Task ${flow.index + 1} of ${flow.session!.queue.length}'),
          title(plan.task.prompt),
          if (plan.task.preparation != null) Text(plan.task.preparation!),
          const SizedBox(height: 16),
          Text('Position: ${postureLabel(plan.task.posture)}'),
          Text('Use your ${flow.actualHand.name} hand.'),
          Text('Phone: ${deviceLabel(plan.task.deviceRole)}'),
          Text(
            '${plan.taskType == TaskType.practice ? 'Practice' : 'Repetition'} ${plan.repetition}',
          ),
          if (plan.task.hand == Hand.either ||
              flow.enrollment!.participant.dominantHand == Hand.either)
            SegmentedButton<Hand>(
              segments: const [
                ButtonSegment(value: Hand.left, label: Text('Left hand')),
                ButtonSegment(value: Hand.right, label: Text('Right hand')),
              ],
              selected: {flow.selectedHand},
              onSelectionChanged: (v) => flow.chooseHand(v.single),
            ),
          button('Ready — start', flow.start),
        ];
      case CollectionPage.countdown:
        return [
          title('Get ready'),
          Semantics(
            liveRegion: true,
            child: Text(
              '${flow.countdown}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const Text('Hold the phone as instructed.'),
        ];
      case CollectionPage.recording:
        return [
          title('Recording'),
          Text(flow.current.task.prompt),
          const LinearProgressIndicator(
            semanticsLabel: 'Recording in progress',
          ),
          button(
            'Stop recording',
            flow.busy ? null : () => unawaited(flow.stop()),
          ),
        ];
      case CollectionPage.saving:
        return [
          title('Saving your recording…'),
          const Text('Keep this screen open for a moment.'),
          const LinearProgressIndicator(semanticsLabel: 'Saving recording'),
        ];
      case CollectionPage.saved:
        return [
          title(flow.demo ? 'Demonstration complete' : 'Saved'),
          Text(
            flow.demo
                ? 'You can continue to the next task.'
                : 'Your recording is safely saved on this phone.',
          ),
          button('Continue', flow.next),
        ];
      case CollectionPage.completed:
        return [
          title('Session complete'),
          button('Back to study', flow.busy ? null : flow.returnToStudy),
          button(
            'Change participant',
            flow.busy ? null : flow.changeParticipant,
          ),
          const Text(
            'Thank you. You have finished all tasks for this session.',
          ),
        ];
      case CollectionPage.failed:
        return [
          title('Please repeat this task'),
          button('Try again', flow.busy ? null : () => unawaited(flow.retry())),
        ];
    }
  }
}

String postureLabel(Posture value) => switch (value) {
  Posture.seated => 'Sit comfortably',
  Posture.standing => 'Stand comfortably',
  Posture.supine => 'Lie on your back',
  Posture.unspecified => 'Choose a comfortable position',
};
String deviceLabel(DeviceRole value) => switch (value) {
  DeviceRole.personal => 'Your own phone',
  DeviceRole.phoneA => 'Study phone A',
  DeviceRole.phoneB => 'Study phone B',
};
const supportedSchemaVersion = 1;
