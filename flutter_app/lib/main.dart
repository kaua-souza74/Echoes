import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app_controller.dart';
import 'app/echoes_application.dart';
import 'app/supabase_backend.dart';
import 'app/supabase_config.dart';
import 'app/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const EchoesBootstrap());
}

class EchoesBootstrap extends StatefulWidget {
  const EchoesBootstrap({super.key});
  @override
  State<EchoesBootstrap> createState() => _EchoesBootstrapState();
}

class _EchoesBootstrapState extends State<EchoesBootstrap> {
  late Future<AppController> _startup = _start();
  AppController? _controller;
  Future<AppController> _start() async {
    final config = SupabaseConfig.environment();
    config.validate();
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.key,
      debug: false,
    );
    return _controller = AppController(
      SupabaseBackend(Supabase.instance.client),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppController>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return EchoesApplication(controller: snapshot.data!);
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: EchoBackdrop(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'E C H O E S',
                      style: TextStyle(fontSize: 36, color: lume),
                    ),
                    const SizedBox(height: 24),
                    if (snapshot.hasError) ...[
                      const Text(
                        'O acesso não pôde ser iniciado. Confira a conexão com a internet e tente novamente.',
                        textAlign: TextAlign.center,
                      ),
                      EchoButton(
                        'Tentar novamente',
                        onPressed: () => setState(() => _startup = _start()),
                      ),
                    ] else
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
