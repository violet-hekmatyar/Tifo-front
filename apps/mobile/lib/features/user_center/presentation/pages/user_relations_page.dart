import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../controllers/user_center_controllers.dart';
import 'user_list_page.dart';

class UserRelationsPage extends StatefulWidget {
  const UserRelationsPage({required this.userId, super.key});
  final int userId;

  @override
  State<UserRelationsPage> createState() => _UserRelationsPageState();
}

class _UserRelationsPageState extends State<UserRelationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _pageStorage = PageStorageBucket();
  final _followingScroll = ScrollController();
  final _followersScroll = ScrollController();
  double _followingOffset = 0;
  double _followersOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
    _followingScroll.addListener(() {
      if (_followingScroll.hasClients && _followingScroll.position.pixels > 0) {
        _followingOffset = _followingScroll.position.pixels;
      }
    });
    _followersScroll.addListener(() {
      if (_followersScroll.hasClients && _followersScroll.position.pixels > 0) {
        _followersOffset = _followersScroll.position.pixels;
      }
    });
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _followingScroll.dispose();
    _followersScroll.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _tabs.index == 0 ? _followingScroll : _followersScroll;
      final offset = _tabs.index == 0 ? _followingOffset : _followersOffset;
      if (!target.hasClients || offset <= 0) return;
      target.jumpTo(offset.clamp(0, target.position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    body: SafeArea(
      child: widget.userId <= 0
          ? const Center(child: Text('用户不存在'))
          : Column(
              children: [
                SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('relations_back'),
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: TabBar(
                          controller: _tabs,
                          labelColor: AppColors.brand,
                          unselectedLabelColor: AppColors.inkMuted,
                          indicatorColor: AppColors.brand,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(
                              key: ValueKey('relations_following'),
                              text: '关注',
                            ),
                            Tab(
                              key: ValueKey('relations_followers'),
                              text: '粉丝',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: PageStorage(
                    bucket: _pageStorage,
                    child: IndexedStack(
                      index: _tabs.index,
                      children: [
                        UserListView(
                          key: const ValueKey('relations_list_following'),
                          scrollController: _followingScroll,
                          request: UserListRequest(
                            UserListKind.followings,
                            userId: widget.userId,
                          ),
                          showSearch: true,
                          searchHint: '搜索已关注的人',
                          active: true,
                        ),
                        UserListView(
                          key: const ValueKey('relations_list_followers'),
                          scrollController: _followersScroll,
                          request: UserListRequest(
                            UserListKind.followers,
                            userId: widget.userId,
                          ),
                          showSearch: true,
                          searchHint: '搜索粉丝',
                          active: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}
