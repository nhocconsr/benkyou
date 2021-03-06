import 'package:benkyou/models/Card.dart' as CardModel;
import 'package:benkyou/services/database/DBProvider.dart';
import 'package:benkyou/services/database/Database.dart';
import 'package:benkyou/services/navigator.dart';
import 'package:benkyou/utils/utils.dart';
import 'package:benkyou/widgets/AddAnswerCardWidget.dart';
import 'package:benkyou/widgets/Header.dart';
import 'package:benkyou/animations/ShowUp.dart';
import 'package:benkyou/widgets/app/BasicContainer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LateInitPage extends StatefulWidget {
  final int deckId;

  LateInitPage({
    Key key, this.deckId,
  }) : super(key: key);

  @override
  _LateInitPageState createState() => _LateInitPageState();
}

class _LateInitPageState extends State<LateInitPage>
    with TickerProviderStateMixin {
  AppDatabase database;
  List<CardModel.Card> remainingCards;
  int index = 0;
  int maxIndex = 0;
  GlobalKey<AddAnswerCardWidgetState> answerWidgetKey =
  new GlobalKey<AddAnswerCardWidgetState>();

  @override
  void initState() {
    super.initState();
    loadRemainingCards();
  }

  void loadRemainingCards() async {
    database = await DBProvider.db.database;
    remainingCards = await database.cardDao.findCardsWithoutSolution(deckId: widget.deckId);
    setState(() {
      maxIndex = remainingCards.length - 1;
    });
    // security
    if (maxIndex == -1){
      goToHomePage(context);
    }
  }

  void _deleteNotInitCard(int index) async{
    database = await DBProvider.db.database;
    await database.cardDao.deleteCard(remainingCards[index].id);
    _reindexCards(index);
  }

  void _navigateThroughCards(bool isUp) {
    if ((index >= maxIndex && isUp) || (index == 0 && !isUp)) {
      return;
    }
    this.setState(() {
      index += (isUp ? 1 : -1);
    });
  }

  void _addAnswers() async {
    List<String> answers = [];
    int toRemoveIndex = index;

    for (var answerController in answerWidgetKey.currentState
        .textEditingControllers) {
      if (answerController.text != null && answerController.text.isNotEmpty) {
        answers.add(answerController.text.toLowerCase());
      }
    }
    if (answers.isEmpty) {
      print('no answer');
      //TODO
      return;
    }

    await CardModel.Card.setCardWithBasicAnswers(
        remainingCards[index].deckId, remainingCards[index].question, answers,
        card: remainingCards[index], hint: remainingCards[index].hint);

    _reindexCards(toRemoveIndex);
  }

  void _reindexCards(int toRemoveIndex){
    maxIndex = maxIndex - 1;
    index = (index == 0) ? 0 : index - 1;
    setState(() {
      remainingCards.removeAt(toRemoveIndex);
      if (remainingCards.isEmpty){
        goToDeckInfoPage(context, widget.deckId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasicContainer(
        child: Column(children: <Widget>[
          Header(
              title: 'Cards without answers',
              type: HEADER_DEFAULT,
            backFunction: (){
                goToDeckInfoPage(context, widget.deckId);
            },
          ),
          Expanded(
            flex: 2,
            child: Stack(
              children: <Widget>[
                Container(
                  child: Center(
                      child: Column(
                        children: <Widget>[
                          ShowUp(
                            child: Text(
                              remainingCards != null && remainingCards.isNotEmpty ? remainingCards[index]
                                  .question : '',
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                          Text(
                            remainingCards != null && remainingCards.isNotEmpty ? (remainingCards[index].hint ??  '') : '',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                        mainAxisAlignment: MainAxisAlignment.center,
                      ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _navigateThroughCards(false);
                  },
                  child: Opacity(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'resources/imgs/arrow_backward_black.png',
                        width: 50.0,
                      ),
                    ), opacity: index == 0 ? 0.2 : 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _navigateThroughCards(true);
                  },
                  child: Opacity(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Image.asset(
                        'resources/imgs/arrow_forward_black.png',
                        width: 50.0,
                      ),
                    ), opacity: index >= maxIndex ? 0.2 : 1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 7,
            child: Container(
              color: Color(0xffE3E3E3),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Container(
                        padding: EdgeInsets.only(
                            top: 20.0, left: 50.0, right: 50.0),
                        child: AddAnswerCardWidget(key: answerWidgetKey)),
                  ],
                ),
              ),
            ),
          ),
          isKeyboardVisible(context) ? Container() :
          Expanded(
            child: GestureDetector(
              onTap: () {
                _deleteNotInitCard(index);
              },
              child: Container(
                color: Colors.red,
                child: Center(
                    child: Text(
                      'DISCARD CARD',
                      style: TextStyle(color: Colors.white, fontSize: 30),
                    )),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _addAnswers();
              },
              child: Container(
                color: Colors.blue,
                child: Center(
                    child: Text(
                      'ADD CARD',
                      style: TextStyle(color: Colors.white, fontSize: 30),
                    )),
              ),
            ),
          )
        ]));
  }
}
