import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/base_auth_user_provider.dart';

import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => appStateNotifier.loggedIn
          ? PostAuthGatePageWidget()
          : DashboardPageWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => appStateNotifier.loggedIn
              ? PostAuthGatePageWidget()
              : DashboardPageWidget(),
        ),
        FFRoute(
          name: HomePageWidget.routeName,
          path: HomePageWidget.routePath,
          builder: (context, params) => HomePageWidget(),
        ),
        FFRoute(
          name: CreateAccountPageWidget.routeName,
          path: CreateAccountPageWidget.routePath,
          builder: (context, params) => CreateAccountPageWidget(
            afterCompleteRouteName: params.getParam(
              'afterCompleteRouteName',
              ParamType.String,
            ),
            loginRouteName: params.getParam(
              'loginRouteName',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: LocationSelectPageWidget.routeName,
          path: LocationSelectPageWidget.routePath,
          builder: (context, params) => LocationSelectPageWidget(
            speciality: params.getParam(
              'speciality',
              ParamType.String,
            ),
            initialProvince: params.getParam(
              'initialProvince',
              ParamType.String,
            ),
            category: params.getParam(
              'category',
              ParamType.String,
            ),
            searchText: params.getParam(
              'searchText',
              ParamType.String,
            ),
            preselectedProvince: params.getParam(
              'preselectedProvince',
              ParamType.String,
            ),
            initialRegion: params.getParam(
              'initialRegion',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ListingResultsPageWidget.routeName,
          path: ListingResultsPageWidget.routePath,
          builder: (context, params) => ListingResultsPageWidget(
            province: params.getParam(
              'province',
              ParamType.String,
            ),
            city: params.getParam(
              'city',
              ParamType.String,
            ),
            speciality: params.getParam(
              'speciality',
              ParamType.String,
            ),
            category: params.getParam(
              'category',
              ParamType.String,
            ),
            searchText: params.getParam(
              'searchText',
              ParamType.String,
            ),
            provinceSlug: params.getParam(
              'provinceSlug',
              ParamType.String,
            ),
            categorySlug: params.getParam(
              'categorySlug',
              ParamType.String,
            ),
            specialitySlug: params.getParam(
              'specialitySlug',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ListingDetailPageWidget.routeName,
          path: ListingDetailPageWidget.routePath,
          builder: (context, params) => ListingDetailPageWidget(
            listingRef: params.getParam(
              'listingRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['subby_listings'],
            ),
          ),
        ),
        FFRoute(
          name: LoginWidget.routeName,
          path: LoginWidget.routePath,
          builder: (context, params) => LoginWidget(
            defaultCountryCode: params.getParam(
              'defaultCountryCode',
              ParamType.String,
            ),
            afterLoginRouteName: params.getParam(
              'afterLoginRouteName',
              ParamType.String,
            ),
            createAccountRouteName: params.getParam(
              'createAccountRouteName',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: PostAuthGatePageWidget.routeName,
          path: PostAuthGatePageWidget.routePath,
          builder: (context, params) => PostAuthGatePageWidget(),
        ),
        FFRoute(
          name: ProfilePageWidget.routeName,
          path: ProfilePageWidget.routePath,
          builder: (context, params) => ProfilePageWidget(),
        ),
        FFRoute(
          name: SavedPageWidget.routeName,
          path: SavedPageWidget.routePath,
          builder: (context, params) => SavedPageWidget(),
        ),
        FFRoute(
          name: ExplorePageWidget.routeName,
          path: ExplorePageWidget.routePath,
          builder: (context, params) => ExplorePageWidget(),
        ),
        FFRoute(
          name: MorePageWidget.routeName,
          path: MorePageWidget.routePath,
          builder: (context, params) => MorePageWidget(),
        ),
        FFRoute(
          name: TermsPageWidget.routeName,
          path: TermsPageWidget.routePath,
          builder: (context, params) => TermsPageWidget(),
        ),
        FFRoute(
          name: PrivacyPageWidget.routeName,
          path: PrivacyPageWidget.routePath,
          builder: (context, params) => PrivacyPageWidget(),
        ),
        FFRoute(
          name: EditProfilePageWidget.routeName,
          path: EditProfilePageWidget.routePath,
          builder: (context, params) => EditProfilePageWidget(),
        ),
        FFRoute(
          name: DashboardPageWidget.routeName,
          path: DashboardPageWidget.routePath,
          builder: (context, params) => DashboardPageWidget(),
        ),
        FFRoute(
          name: SupportPageWidget.routeName,
          path: SupportPageWidget.routePath,
          builder: (context, params) => SupportPageWidget(),
        ),
        FFRoute(
          name: ProjectDetailPageWidget.routeName,
          path: ProjectDetailPageWidget.routePath,
          builder: (context, params) => ProjectDetailPageWidget(
            projectRef: params.getParam(
              'projectRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['projects'],
            ),
            listingRef: params.getParam(
              'listingRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['subby_listings'],
            ),
          ),
        ),
        FFRoute(
          name: AddListingPageWidget.routeName,
          path: AddListingPageWidget.routePath,
          builder: (context, params) => AddListingPageWidget(),
        ),
        FFRoute(
          name: EditListingPageWidget.routeName,
          path: EditListingPageWidget.routePath,
          builder: (context, params) => EditListingPageWidget(
            listingRef: params.getParam(
              'listingRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['subby_listings'],
            ),
          ),
        ),
        FFRoute(
          name: AddProjectsPageWidget.routeName,
          path: AddProjectsPageWidget.routePath,
          builder: (context, params) => AddProjectsPageWidget(),
        ),
        FFRoute(
          name: EditProjectPageWidget.routeName,
          path: EditProjectPageWidget.routePath,
          builder: (context, params) => EditProjectPageWidget(
            projectRef: params.getParam(
              'projectRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['projects'],
            ),
          ),
        ),
        FFRoute(
          name: ProjectTimelinePageWidget.routeName,
          path: ProjectTimelinePageWidget.routePath,
          builder: (context, params) => ProjectTimelinePageWidget(),
        ),
        FFRoute(
          name: ProjectCostPageWidget.routeName,
          path: ProjectCostPageWidget.routePath,
          builder: (context, params) => ProjectCostPageWidget(),
        ),
        FFRoute(
          name: SnagListPageWidget.routeName,
          path: SnagListPageWidget.routePath,
          builder: (context, params) => SnagListPageWidget(),
        ),
        FFRoute(
          name: GetQuotesPageWidget.routeName,
          path: GetQuotesPageWidget.routePath,
          builder: (context, params) => GetQuotesPageWidget(),
        ),
        FFRoute(
          name: ToDoListPageWidget.routeName,
          path: ToDoListPageWidget.routePath,
          builder: (context, params) => ToDoListPageWidget(),
        ),
        FFRoute(
          name: DocumentUploadPageWidget.routeName,
          path: DocumentUploadPageWidget.routePath,
          builder: (context, params) => DocumentUploadPageWidget(
            projectRef: params.getParam(
              'projectRef',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['projects'],
            ),
          ),
        ),
        FFRoute(
          name: AddSnagPageWidget.routeName,
          path: AddSnagPageWidget.routePath,
          builder: (context, params) => AddSnagPageWidget(),
        ),
        FFRoute(
          name: DetailSnagPageWidget.routeName,
          path: DetailSnagPageWidget.routePath,
          builder: (context, params) => DetailSnagPageWidget(),
        ),
        FFRoute(
          name: AddTaskPageWidget.routeName,
          path: AddTaskPageWidget.routePath,
          builder: (context, params) => AddTaskPageWidget(),
        ),
        FFRoute(
          name: DetailTaskPageWidget.routeName,
          path: DetailTaskPageWidget.routePath,
          builder: (context, params) => DetailTaskPageWidget(),
        ),
        FFRoute(
          name: SubmitQuoteWidget.routeName,
          path: SubmitQuoteWidget.routePath,
          builder: (context, params) => SubmitQuoteWidget(),
        ),
        FFRoute(
          name: QuotesReceivedWidget.routeName,
          path: QuotesReceivedWidget.routePath,
          builder: (context, params) => QuotesReceivedWidget(),
        ),
        FFRoute(
          name: QuoteDetailWidget.routeName,
          path: QuoteDetailWidget.routePath,
          builder: (context, params) => QuoteDetailWidget(),
        ),
        FFRoute(
          name: InviteWidget.routeName,
          path: InviteWidget.routePath,
          builder: (context, params) => InviteWidget(),
        ),
        FFRoute(
          name: QuoteRequestWidget.routeName,
          path: QuoteRequestWidget.routePath,
          builder: (context, params) => QuoteRequestWidget(),
        ),
        FFRoute(
          name: InboxWidget.routeName,
          path: InboxWidget.routePath,
          builder: (context, params) => InboxWidget(),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/dashboardPage';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? Container(
                  color: Colors.transparent,
                  child: Image.asset(
                    'assets/images/splash-green-wordmark-1170x2532.png',
                    fit: BoxFit.cover,
                  ),
                )
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
