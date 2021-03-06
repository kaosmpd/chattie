import 'package:chattie/providers/providers.dart';
import 'package:chattie/utils/constants.dart';
import 'package:chattie/widgets/add_contact_page/search_body.dart';
import 'package:chattie/widgets/ui/base_divider.dart';
import 'package:chattie/widgets/ui/base_input.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

final searchStateProvider = StateProvider.autoDispose<SearchState>((ref) {
  return SearchState.beforeSearching;
});
final searchResultProvider = StateProvider.autoDispose<Map?>((ref) => null);

class AddContactPage extends StatefulWidget {
  const AddContactPage({Key? key}) : super(key: key);

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  void handleBackToContacts(BuildContext context) {
    Navigator.pop(context);
  }

  void setSearchResultState(
      WidgetRef ref, SearchState searchState, Map? searchResult) {
    ref.read(searchStateProvider.notifier).state = searchState;
    ref.read(searchResultProvider.notifier).state = searchResult;
  }

  void handleSearch(String inputText, WidgetRef ref) async {
    final currentUserUid = ref.watch(currentUserUidProvider);

    if (inputText.isEmpty) {
      setSearchResultState(ref, SearchState.beforeSearching, null);
      return;
    }

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    final searchEvent = await dbRef
        .child('users')
        .orderByChild('username')
        .equalTo(inputText)
        .once();

    if (!searchEvent.snapshot.exists) {
      setSearchResultState(ref, SearchState.empty, null);
      return;
    }

    final userFound = searchEvent.snapshot.value as Map;
    final userFoundKey = userFound.keys.toList().first;
    final userFoundValue = userFound.values.toList().first;

    final checkIfExistInContactsEvent = await dbRef
        .child('contacts/$currentUserUid')
        .orderByValue()
        .equalTo(userFoundKey)
        .once();

    final searchResult = {
      ...userFoundValue,
      'isExistInContacts': checkIfExistInContactsEvent.snapshot.exists,
    };

    setSearchResultState(ref, SearchState.hasResult, searchResult);
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: appBarPadding,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => handleBackToContacts(context),
                    child: SvgPicture.asset(
                      'assets/icons/linear/left_arrow.svg',
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) => BaseInput(
                          onChanged: (text) => handleSearch(text, ref),
                          labelText: 'Search Chattie',
                          controller: searchController),
                    ),
                  ),
                ],
              ),
            ),
            const BaseDivider(),
            const Expanded(
              child: Center(
                child: SearchBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
