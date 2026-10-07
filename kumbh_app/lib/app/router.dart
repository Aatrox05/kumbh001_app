import 'package:flutter/material.dart';
import 'package:kumbh_app/features/home/presentation/home_screen.dart';
import 'package:kumbh_app/features/splash/presentation/splash_screen.dart';
import 'package:kumbh_app/features/language/presentation/language_selection_screen.dart';
import 'package:kumbh_app/features/chat/presentation/chat_screen.dart';
import 'package:kumbh_app/features/events/presentation/events_screen.dart';
import 'package:kumbh_app/features/announcements/presentation/announcements_screen.dart';
import 'package:kumbh_app/features/more/presentation/placeholder_content_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/language':
        return MaterialPageRoute(
            builder: (_) => const LanguageSelectionScreen());
      case '/language_selected':
        final lang = settings.arguments as String? ?? 'English';
        return MaterialPageRoute(
            builder: (_) => LanguageSelectedScreen(selectedLanguage: lang));
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/chat':
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case '/events':
        return MaterialPageRoute(builder: (_) => const EventsScreen());
      case '/announcements':
        return MaterialPageRoute(builder: (_) => const AnnouncementsScreen());
      case '/content':
        final title = settings.arguments as String? ?? 'Content';
        return MaterialPageRoute(
            builder: (_) => PlaceholderContentScreen(title: title));
      case '/details':
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Details')),
            body: const Center(child: Text('Content Description Page')),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
