import 'package:chattie/providers/providers.dart';
import 'package:chattie/utils/constants.dart';
import 'package:chattie/widgets/layouts/custom_app_bar.dart';
import 'package:chattie/widgets/layouts/custom_tab_bar.dart';
import 'package:chattie/widgets/tab_views/chats_view.dart';
import 'package:chattie/widgets/tab_views/contacts_view.dart';
import 'package:chattie/widgets/tab_views/settings_view.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  TabItems _currentTab = TabItems.chats;
  List? contacts;
  List<Map>? previewMessages;

  @override
  void initState() {
    super.initState();
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    final currentUserUid = ref.read(currentUserUidProvider);

    dbRef.child('contacts/$currentUserUid').onValue.listen((event) async {
      List<Map> contactsListWithUserInfo = [];
      List contactsList =
          event.snapshot.exists ? event.snapshot.value as List : [];
      for (String contact in contactsList) {
        final snapshot = await dbRef.child('users/$contact').get();
        contactsListWithUserInfo.add(snapshot.value as Map);
      }
      if (mounted) {
        setState(() {
          contacts = contactsListWithUserInfo;
        });
      }
    });

    dbRef
        .child('messages/preview/$currentUserUid')
        .onValue
        .listen((event) async {
      List<Map> previewsWithUserInfo = [];
      final Map previews =
          event.snapshot.exists ? event.snapshot.value! as Map : {};
      final previewsUid = previews.keys.toList();

      for (String uid in previewsUid) {
        final userSnapshot = await dbRef.child('users/$uid').get();
        final user = userSnapshot.value as Map;
        final previewWithUserInfo = {
          'uid': user['uid'],
          'avatarUri': user['avatarUri'],
          'title': (user['displayName'] as String).isNotEmpty
              ? user['displayName']
              : '@${user['username']}',
          ...previews[uid],
        };
        previewsWithUserInfo.add(previewWithUserInfo);
      }
      if (mounted) {
        setState(() {
          previewMessages = previewsWithUserInfo;
        });
      }
    });
  }

  void _selectTab(TabItems tabItems) {
    setState(() {
      _currentTab = tabItems;
    });
  }

  Widget getTabView() {
    switch (_currentTab) {
      case TabItems.contacts:
        return ContactsView(
          contacts: contacts,
        );
      case TabItems.setting:
        return const SettingViews();
      default:
        return ChatsView(
          previewMessages: previewMessages,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(tabItem: _currentTab),
            Expanded(
              child: getTabView(),
            ),
            CustomTabBar(currentTab: _currentTab, selectTab: _selectTab)
          ],
        ),
      ),
    );
  }
}
