import 'package:flutter/material.dart';
import 'package:poker_game/poker_game.dart';

void main() => runApp(const PokerClient());

class PokerClient extends StatefulWidget {
  const PokerClient({super.key});
  @override
  State<PokerClient> createState() => _PokerClientState();
}

class _PokerClientState extends State<PokerClient> {
  bool dark = true;
  bool preview = false;
  bool table = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pokerlost',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff247c72),
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
    ),
    home: table
        ? GameScreen(
            source: preview ? const PreviewSource() : const UnavailableSource(),
            onReturn: () => setState(() => table = false),
          )
        : Scaffold(
            appBar: AppBar(title: const Text('Pokerlost')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Your table, on every screen',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'The client is ready. Connected gameplay and sign-in are unavailable.',
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('Preview with synthetic data'),
                      value: preview,
                      onChanged: (value) => setState(() => preview = value),
                    ),
                    SwitchListTile(
                      title: const Text('Dark appearance'),
                      value: dark,
                      onChanged: (value) => setState(() => dark = value),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => setState(() => table = true),
                      child: Text(
                        preview ? 'Open preview table' : 'Open table',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}
