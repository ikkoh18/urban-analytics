import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppScaffold extends StatefulWidget {
  final Widget body;
  final Widget? drawer;

  const AppScaffold({
    super.key,
    required this.body,
    this.drawer,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (_searchOpen) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _searchFocus.requestFocus(),
        );
      } else {
        _searchFocus.unfocus();
        _searchCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Urban Analytics System'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      drawer: widget.drawer,
      body: Column(
        children: [
          // Barra de busca animada — aparece abaixo do AppBar
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: _searchOpen ? 56.0 : 0.0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppTheme.navy,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.muted.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                style: const TextStyle(color: AppTheme.offwhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar bairro ou endereço...',
                  hintStyle: TextStyle(
                    color: AppTheme.muted.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.muted,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.muted,
                      size: 18,
                    ),
                    onPressed: _toggleSearch,
                  ),
                  filled: true,
                  fillColor: AppTheme.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}
