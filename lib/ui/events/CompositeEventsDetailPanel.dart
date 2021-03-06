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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/service/LocationServices.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/ui/events/EventsSchedulePanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/widgets/PrivacyTicketsDialog.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:location/location.dart' as Core;

import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/explore/ExploreConvergeDetailItem.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';

import 'package:illinois/ui/WebPanel.dart';
import 'package:sprintf/sprintf.dart';

class CompositeEventsDetailPanel extends StatefulWidget implements AnalyticsPageAttributes {

  final Event parentEvent;
  final Core.LocationData initialLocationData;

  CompositeEventsDetailPanel({this.parentEvent, this.initialLocationData});

  @override
  _CompositeEventsDetailPanelState createState() =>
      _CompositeEventsDetailPanelState();

  @override
  Map<String, dynamic> get analyticsPageAttributes {
    return parentEvent?.analyticsAttributes;
  }
}

class _CompositeEventsDetailPanelState extends State<CompositeEventsDetailPanel>
    implements NotificationsListener {

  static final double _horizontalPadding = 24;

  Core.LocationData _locationData;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      LocationServices.notifyStatusChanged,
      User.notifyPrivacyLevelChanged,
      User.notifyFavoritesUpdated,
    ]);

    _addRecentItem();
    _locationData = widget.initialLocationData;
    _loadCurrentLocation().then((_){
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    _locationData = User().privacyMatch(2) ? await LocationServices.instance.location : null;
  }

  void _updateCurrentLocation() {
    _loadCurrentLocation().then((_){
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.white,
              child: CustomScrollView(
                scrollDirection: Axis.vertical,
                slivers: <Widget>[
                  SliverToutHeaderBar(
                    context: context,
                    imageUrl: widget.parentEvent.exploreImageURL,
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                        [
                          Stack(
                            children: <Widget>[
                              Container(
                                  color: Colors.white,
                                  child: Column(
                                    children: <Widget>[
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Padding(padding: EdgeInsets.only(left: _horizontalPadding), child:_exploreHeading()),
                                          Column(
                                            children: <Widget>[
                                              Padding(
                                                  padding:
                                                  EdgeInsets.symmetric(horizontal: _horizontalPadding),
                                                  child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: <Widget>[
                                                        _exploreTitle(),
                                                        _eventSponsor(),
                                                        _exploreDetails(),
                                                        _exploreSubTitle(),
                                                        _buildUrlButtons()
                                                      ]
                                                  )
                                              ),
                                            ],
                                          ),
                                          _exploreDescription(),
                                          _buildEventsList(),
                                        ],
                                      ),
                                    ],
                                  )
                              )
                            ],
                          )
                        ],addSemanticIndexes:true),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _exploreHeading() {
    String category = widget.parentEvent?.category;
    bool isFavorite = User().isExploreFavorite(widget.parentEvent);
    bool starVisible = User().favoritesStarVisible;
    return Padding(padding: EdgeInsets.only(top: 16, bottom: 12), child: Row(
      children: <Widget>[
        Text(
          (category != null) ? category.toUpperCase() : "",
          style: TextStyle(
              fontFamily: Styles().fontFamilies.bold,
              fontSize: 14,
              color: Styles().colors.fillColorPrimary,
              letterSpacing: 1),
        ),
        Expanded(child: Container()),
        Visibility(visible: starVisible, child: Container(child: Padding(padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTapHeaderStar,
                child: Semantics(
                    label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization()
                        .getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                    hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx(
                        'widget.card.button.favorite.on.hint', ''),
                    button: true,
                    child: Image.asset(isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png')
                ))
        )),)
      ],
    ),);
  }

  Widget _exploreTitle() {
    return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                widget.parentEvent.exploreTitle,
                style: TextStyle(
                    fontSize: 24,
                    color: Styles().colors.fillColorPrimary),
              ),
            ),
          ],
        ));
  }

  Widget _eventSponsor() {
    String eventSponsorText = widget.parentEvent?.sponsor ?? '';
    bool sponsorVisible = AppString.isStringNotEmpty(eventSponsorText);
    return Visibility(visible: sponsorVisible, child: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                eventSponsorText,
                style: TextStyle(
                    fontSize: 16,
                    color: Styles().colors.textBackground,
                    fontFamily: Styles().fontFamilies.bold),
              ),
            ),
          ],
        )),)
    ;
  }

  Widget _exploreDetails() {
    List<Widget> details = List<Widget>();

    Widget time = _exploreTimeDetail();
    if (time != null) {
      details.add(time);
    }

    Widget location = _exploreLocationDetail();
    if (location != null) {
      details.add(location);
    }

    Widget price = _eventPriceDetail();
    if (price != null) {
      details.add(price);
    }

    Widget converge =  _buildConvergeContent();
    if(converge!=null){
      details.add(converge);
    }


    Widget tags = _exploreTags();
    if(tags != null){
      details.add(tags);
    }

    return (0 < details.length)
        ? Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details))
        : Container();
  }

  Widget _divider(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: Container(
        height: 1,
        color: Styles().colors.fillColorPrimaryTransparent015,
      ),
    );
  }

  Widget _exploreTimeDetail() {
    bool isParentSuper = widget.parentEvent?.isSuperEvent ?? false;
    String displayTime = isParentSuper ? widget.parentEvent?.displaySuperDates : widget.parentEvent?.displayRecurringDates;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Semantics(
          label: displayTime,
          excludeSemantics: true,
          child:Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Image.asset('images/icon-calendar.png'),
                ),
                Expanded(child: Text(displayTime,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.medium,
                        fontSize: 16,
                        color: Styles().colors.textBackground))),
              ],
            ),
          )
      );
    } else {
      return null;
    }
  }

  Widget _exploreLocationDetail() {
    String locationText = ExploreHelper.getLongDisplayLocation(widget.parentEvent, _locationData);
    if (!(widget?.parentEvent?.isVirtual ?? false) && widget?.parentEvent?.location != null && (locationText != null) && locationText.isNotEmpty) {
      return GestureDetector(
        onTap: _onLocationDetailTapped,
        child: Semantics(
            label: locationText,
            hint: Localization().getStringEx('panel.explore_detail.button.directions.hint', ''),
            button: true,
            excludeSemantics: true,
            child:Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child:Image.asset('images/icon-location.png'),
                  ),
                  Expanded(child: Text(locationText,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies.medium,
                          fontSize: 16,
                          color: Styles().colors.textBackground))),
                ],
              ),
            )
        ),
      );
    } else {
      return null;
    }
  }

  Widget _eventPriceDetail() {
    String priceText = widget.parentEvent?.cost;
    if ((priceText != null) && priceText.isNotEmpty) {
      return Semantics(
          excludeSemantics: true,
          child:Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child:Image.asset('images/icon-cost.png'),
                ),
                Expanded(child: Text(priceText,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.medium,
                        fontSize: 16,
                        color: Styles().colors.textBackground))),
              ],
            ),
          )
      );
    } else {
      return null;
    }
  }

  Widget _exploreTags(){
    if(widget.parentEvent?.tags != null){
      List<String> capitalizedTags = widget.parentEvent.tags.map((entry)=>'${entry[0].toUpperCase()}${entry.substring(1)}').toList();
      return Padding(
        padding: const EdgeInsets.only(left: 30),
        child: capitalizedTags != null && capitalizedTags.isNotEmpty ? Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: <Widget>[
                Expanded(child: Container(height: 1, color: Styles().colors.surfaceAccent,),)
              ],),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(Localization().getStringEx('panel.explore_detail.label.related_tags', 'Related Tags:')),
                Container(width: 5,),
                Expanded(
                  child: Text(capitalizedTags.join(', '),
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.regular
                    ),
                  ),
                )
              ],
            ),
          ],
        ) : Container(),
      );
    }
    return Container();
  }

  Widget _exploreSubTitle() {
    String subTitle = widget.parentEvent?.exploreSubTitle;
    if (AppString.isStringEmpty(subTitle)) {
      return Container();
    }
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          subTitle,
          style: TextStyle(
              fontSize: 20,
              color: Styles().colors.textBackground),
        ));
  }

  Widget _exploreDescription() {
    String longDescription = widget.parentEvent.exploreLongDescription;
    bool showDescription = AppString.isStringNotEmpty(longDescription);
    if (!showDescription) {
      return Container();
    }
    return Container(color: Styles().colors.background, child: HtmlWidget(
      longDescription,
      bodyPadding: EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 24),
      textStyle: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies.regular, color: Styles().colors.textBackground),
    ),);
  }

  Widget _buildEventsList() {
    List<Event> eventList = widget.parentEvent.isSuperEvent ? widget.parentEvent.featuredEvents : widget.parentEvent.recurringEvents;
    return _EventsList(events: eventList, parentEvent: widget.parentEvent,);
  }

  Widget _buildUrlButtons() {
    Widget buttonsDivider = Container(height: 12);
    String titleUrl = widget.parentEvent?.titleUrl;
    bool visitWebsiteVisible = AppString.isStringNotEmpty(titleUrl);
    String ticketsUrl = widget.parentEvent?.registrationUrl;
    bool getTicketsVisible = AppString.isStringNotEmpty(ticketsUrl);

    String websiteLabel = Localization().getStringEx('panel.explore_detail.button.visit_website.title', 'Visit website');
    String websiteHint = Localization().getStringEx('panel.explore_detail.button.visit_website.hint', '');

    Widget visitWebsiteButton = (widget.parentEvent?.isSuperEvent ?? false) ?
    Visibility(visible: visitWebsiteVisible, child: SmallRoundedButton(
      label: websiteLabel,
      hint: websiteHint,
      showChevron: true,
      borderColor: Styles().colors.fillColorPrimary,
      onTap: () => _onTapVisitWebsite(titleUrl),),) :
    Visibility(visible: visitWebsiteVisible, child: RoundedButton(
      label: websiteLabel,
      hint: websiteHint,
      backgroundColor: Colors.white,
      borderColor: Styles().colors.fillColorSecondary,
      textColor: Styles().colors.fillColorPrimary,
      onTap: () => _onTapVisitWebsite(titleUrl),
    ),);

    return Container(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        visitWebsiteButton,
        Visibility(visible: visitWebsiteVisible, child: buttonsDivider),
        Visibility(visible: getTicketsVisible, child: RoundedButton(
          label: Localization().getStringEx('panel.explore_detail.button.get_tickets.title', 'Get tickets'),
          hint: Localization().getStringEx('panel.explore_detail.button.get_tickets.hint', ''),
          backgroundColor: Colors.white,
          borderColor: Styles().colors.fillColorSecondary,
          textColor: Styles().colors.fillColorPrimary,
          onTap: () => _onTapGetTickets(ticketsUrl),
        ),),
        Visibility(visible: getTicketsVisible, child: buttonsDivider)
      ],
    ));
  }

  void _onTapVisitWebsite(String url) {
    Analytics.instance.logSelect(target: "Website");
    _onTapWebButton(url, 'Website');
  }

  Widget _buildConvergeContent() {
    int eventConvergeScore = (widget.parentEvent != null) ? widget.parentEvent?.convergeScore : null;
    String eventConvergeUrl = (widget.parentEvent != null) ? widget.parentEvent?.convergeUrl : null;
    bool hasConvergeScore = (eventConvergeScore != null) && eventConvergeScore>0;
    bool hasConvergeUrl = !AppString.isStringEmpty(eventConvergeUrl);
    bool hasConvergeContent = hasConvergeScore || hasConvergeUrl;

    return !hasConvergeContent? Container():
    Column(
        children:<Widget>[
          _divider(),
          Padding(padding: EdgeInsets.only(top: 10),child:
          ExploreConvergeDetailButton(eventConvergeScore: eventConvergeScore, eventConvergeUrl: eventConvergeUrl,)
          )
        ]
    );
  }

  void _addRecentItem() {
    RecentItems().addRecentItem(RecentItem.fromOriginalType(widget.parentEvent));
  }

  void _onTapGetTickets(String ticketsUrl) {
    Analytics.instance.logSelect(target: "Tickets");
    if (User().showTicketsConfirmationModal) {
      PrivacyTicketsDialog.show(
          context, onContinueTap: () {
        _onTapWebButton(ticketsUrl, 'Tickets');
      });
    } else {
      _onTapWebButton(ticketsUrl, 'Tickets');
    }
  }

  void _onTapWebButton(String url, String analyticsName){
    if(AppString.isStringNotEmpty(url)){
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) =>
                  WebPanel(
                      analyticsName: "WebPanel($analyticsName)",
                      url: url)));
    }
  }

  void _onLocationDetailTapped(){
    if(widget?.parentEvent?.location?.latitude != null && widget?.parentEvent?.location?.longitude != null) {
      Analytics.instance.logSelect(target: "Location Detail");
      NativeCommunicator().launchExploreMapDirections(target: widget.parentEvent);
    }
  }

  void _onTapHeaderStar() {
    Analytics.instance.logSelect(target: "MultipleEventsDetailPanel mark favorite event: ${widget.parentEvent?.id ?? 'all recurring events'}");
    Event event = widget.parentEvent;
    if (event?.isRecurring ?? false) {
      if (User().isExploreFavorite(event)) {
        User().removeAllFavorites(event.recurringEvents);
      } else {
        User().addAllFavorites(event.recurringEvents);
      }
    } else {
      User().switchFavorite(event);
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == LocationServices.notifyStatusChanged) {
      _updateCurrentLocation();
    }
    else if (name == User.notifyPrivacyLevelChanged) {
      _updateCurrentLocation();
    }
    else if (name == User.notifyFavoritesUpdated) {
      setState(() {});
    }
  }
}

class _EventsList extends StatefulWidget {

  final List<Event> events;
  final Event parentEvent;

  _EventsList({this.events, this.parentEvent});

  _EventsListState createState() => _EventsListState();
}

class _EventsListState extends State<_EventsList>{

  static final int _minVisibleItems = 5;

  @override
  Widget build(BuildContext context) {
    String titleKey = widget.parentEvent.isSuperEvent
        ? "panel.explore_detail.super_event.schedule.heading.title"
        : "panel.explore_detail.recurring_event.schedule.heading.title";
    return SectionTitlePrimary(
        title: Localization().getStringEx(titleKey, "Event Schedule"),
        subTitle: "",
        slantImageRes: "images/slant-down-right-grey.png",
        slantColor: Styles().colors.backgroundVariant,
        textColor: Styles().colors.fillColorPrimary,
        children: _buildListItems()
    );
  }

  List<Widget> _buildListItems() {
    List<Widget> listItems = List<Widget>();
    bool isParentSuper = widget.parentEvent.isSuperEvent;
    if (AppCollection.isCollectionNotEmpty(widget.events)) {
      for (Event event in widget.events) {
        listItems.add(_EventEntry(event: event, parentEvent: widget.parentEvent,));
        if (isParentSuper && (listItems.length >= _minVisibleItems)) {
          break;
        }
      }
    }
    if (isParentSuper) {
      listItems.add(_buildFullScheduleButton());
    }
    return listItems;
  }

  Widget _buildFullScheduleButton() {
    String titleFormat = Localization().getStringEx("panel.explore_detail.button.see_super_events.title", "All %s");
    String title = sprintf(titleFormat, [widget.parentEvent.title]);
    return Column(
      children: <Widget>[
        Semantics(
          label: title,
          button: true,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: _onTapFullSchedule,
            child: Container(
              color: Styles().colors.fillColorPrimary,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Colors.white),),
                    ),
                    Image.asset('images/chevron-right.png')
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onTapFullSchedule() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => EventsSchedulePanel(superEvent: widget.parentEvent)));
  }
}

class _EventEntry extends StatelessWidget {

  final Event event;
  final Event parentEvent;

  _EventEntry({this.event, this.parentEvent});

  @override
  Widget build(BuildContext context) {
    bool isFavorite = User().isFavorite(event);
    bool starVisible = User().favoritesStarVisible;
    String title = parentEvent.isSuperEvent ? event.title : event.displayDate;
    String subTitle = parentEvent.isSuperEvent ? event.displaySuperTime : event.displayStartEndTime;
    return GestureDetector(onTap: () => _onTapEvent(context), child: Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors.surfaceAccent, width: 1.0), borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(padding: EdgeInsets.all(16), child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies.bold, color: Styles().colors.fillColorPrimary),),
              Text(subTitle, overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 14, fontFamily: Styles().fontFamilies.medium, color: Styles().colors.textBackground, letterSpacing: 0.5),)
            ],),),
          Visibility(
            visible: starVisible, child: Container(child: Padding(padding: EdgeInsets.only(left: 24),
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Analytics.instance.logSelect(target: "Favorite");
                    User().switchFavorite(event);
                  },
                  child: Semantics(
                      label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization()
                          .getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                      hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx(
                          'widget.card.button.favorite.on.hint', ''),
                      button: true,
                      child: Image.asset(isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png')
                  ))
          )),)
        ],),),
    ),);
  }

  void _onTapEvent(BuildContext context) {
    if (parentEvent.isSuperEvent) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreEventDetailPanel(event: event, superEventTitle: parentEvent.title)));
    }
  }
}
