/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Parking.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/TransportationService.dart';
import 'package:illinois/ui/parking/ParkingEventPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/service/Styles.dart';

class ParkingEventsPanel extends StatefulWidget{

  _ParkingEventsPanelState createState() => _ParkingEventsPanelState();
}

class _ParkingEventsPanelState extends State<ParkingEventsPanel>{

  bool _isLoading = false;

  List<ParkingEvent> _events;

  @override
  void initState() {
    super.initState();

    _loadParkingEvents();
  }

  void _loadParkingEvents(){
    setState(() {
      _isLoading = true;
    });
    TransportationService().loadParkingEvents().then((List<ParkingEvent> events){
      _events = events;
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
        Localization().getStringEx("panel.parking_events.label.heading","Events"),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0),
        ),
      ),
      body: _buildScaffoldBody(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildScaffoldBody() {
    return _isLoading ? _buildLoadingWidget() : ((_events != null && _events.length > 0) ? _buildContentWidget() : _buildEmptyWidget());
  }

  Widget _buildLoadingWidget() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  Container(height: 5,),
                  Text(
                    Localization().getStringEx("panel.parking_events.label.loading", "Loading parking events. Please wait..."),
                    style: TextStyle(
                      fontFamily: Styles().fontFamilies.regular,
                      fontSize: 16,
                      color: Styles().colors.mediumGray,
                    ),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildEmptyWidget() {
    return Center(child: Text(Localization().getStringEx("panel.parking_events.label.no_events", "No parking events."), style: TextStyle(
      fontFamily: Styles().fontFamilies.bold,
      fontSize: 18,
      color: Styles().colors.fillColorPrimary,
    ),),);
  }

  Widget _buildContentWidget() {
    return ListView.separated(
        itemBuilder: (context, index) {
          ParkingEvent event = _events[index];
          return _ParkingEventWidget(event: event,);
        },
        separatorBuilder: (context, index) => Container(height: 1, color: Styles().colors.lightGray,),
        itemCount: _events != null ? _events.length : 0);
  }
}

class _ParkingEventWidget extends StatelessWidget{
  final ParkingEvent event;

  _ParkingEventWidget({this.event});

  @override
  Widget build(BuildContext context) {
    String status = event.live ?  Localization().getStringEx("panel.parking_events.label.status.active","active") :
                                  Localization().getStringEx("panel.parking_events.label.status.inactive", "inactive");
    return GestureDetector(
      onTap: ()=>_navigateEvent(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              event.name,
                style: TextStyle(
                  fontFamily: Styles().fontFamilies.bold,
                  fontSize: 18,
                  color: Styles().colors.fillColorPrimary,
                ),
            ),
            Text(
              Localization().getStringEx("panel.parking_events.label.from","From: ")+"${event.displayParkingFromDate}",
              style: TextStyle(
                fontFamily: Styles().fontFamilies.regular,
                fontSize: 16,
                color: Styles().colors.mediumGray,
              ),
            ),
            Text(
              Localization().getStringEx("panel.parking_events.label.to","To: ")+"${event.displayParkingToDate}",
              style: TextStyle(
                fontFamily: Styles().fontFamilies.regular,
                fontSize: 16,
                color: Styles().colors.mediumGray,
              ),
            ),
            Text(
              Localization().getStringEx("panel.parking_events.label.status","Status: ")+"$status",
              style: TextStyle(
                fontFamily: Styles().fontFamilies.regular,
                fontSize: 16,
                color: Styles().colors.mediumGray,
              ),
            )
          ],
        ),
      ),
    );
  }

  void _navigateEvent(BuildContext context) {
    Analytics.instance.logSelect(target: "Event");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ParkingEventPanel(event: event,)));
  }
}