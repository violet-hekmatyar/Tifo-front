import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('关注与粉丝'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(key: ValueKey('relations_following'), text: '关注'),
          Tab(key: ValueKey('relations_followers'), text: '粉丝'),
        ],
      ),
    ),
    body: widget.userId <= 0
        ? const Center(child: Text('用户不存在'))
        : PageStorage(
            bucket: _pageStorage,
            child: TabBarView(
              controller: _tabs,
              children: [
                UserListView(
                  key: const ValueKey('relations_list_following'),
                  request: UserListRequest(
                    UserListKind.followings,
                    userId: widget.userId,
                  ),
                  showSearch: true,
                  active: _tabs.index == 0,
                ),
                UserListView(
                  key: const ValueKey('relations_list_followers'),
                  request: UserListRequest(
                    UserListKind.followers,
                    userId: widget.userId,
                  ),
                  showSearch: true,
                  active: _tabs.index == 1,
                ),
              ],
            ),
          ),
  );
}
