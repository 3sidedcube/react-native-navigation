/*eslint-disable*/
import React, {Component} from 'react';
import {
  NativeAppEventEmitter,
  DeviceEventEmitter,
  Platform
} from 'react-native';
import platformSpecific from './deprecated/platformSpecificDeprecated';
import Navigation from './Navigation';

const _allNavigatorEventHandlers = {};

const NavigationSpecific = {
  push: platformSpecific.navigatorPush,
  pop: platformSpecific.navigatorPop,
  popToRoot: platformSpecific.navigatorPopToRoot,
  resetTo: platformSpecific.navigatorResetTo
};

class Navigator {
  constructor(navigatorID, navigatorEventID, screenInstanceID) {
    this.navigatorID = navigatorID;
    this.screenInstanceID = screenInstanceID;
    this.navigatorEventID = navigatorEventID;
    this.navigatorEventHandler = null;
    this.navigatorEventSubscription = null;
  }

  push(params = {}) {
    return NavigationSpecific.push(this, params);
  }

  pop(params = {}) {
    return NavigationSpecific.pop(this, params);
  }

  popToRoot(params = {}) {
    return NavigationSpecific.popToRoot(this, params);
  }

  resetTo(params = {}) {
    return NavigationSpecific.resetTo(this, params);
  }

  showModal(params = {}) {
    return Navigation.showModal(params);
  }

  dismissModal(params = {}) {
    return Navigation.dismissModal(params);
  }

  dismissAllModals(params = {}) {
    return Navigation.dismissAllModals(params);
  }

  showLightBox(params = {}) {
    return Navigation.showLightBox(params);
  }

  dismissLightBox(params = {}) {
    return Navigation.dismissLightBox(params);
  }

  showInAppNotification(params = {}) {
    return Navigation.showInAppNotification(params);
  }

  dismissInAppNotification(params = {}) {
    return Navigation.dismissInAppNotification(params);
  }

  setButtons(params = {}) {

    if (params.leftButtons) {

      params.leftButtons.forEach(leftButton => {

        if (leftButton.render) {

          const generatorWrapper = function() {
            return class extends Component {
              render() {
                return leftButton.render();
              }
            }
          }

          Navigation.registerSupplementaryComponent(leftButton.id, generatorWrapper)        
        }
      });
    }

    if (params.rightButtons) {

      params.rightButtons.forEach(rightButton => {

        if (rightButton.render) {

          const generatorWrapper = function() {
            return class extends Component {
              render() {
                return rightButton.render();
              }
            }
          }

          Navigation.registerSupplementaryComponent(rightButton.id, generatorWrapper)        
        }
      });
    }

    return platformSpecific.navigatorSetButtons(this, this.navigatorEventID, params);
  }

  setTitleView(renderFunction = () => {return null;}) {

    const generatorWrapper = function() {
      return class extends Component {
        render() {
          return renderFunction();
        }
      }
    }

    Navigation.registerSupplementaryComponent(this.screenInstanceID+".title", generatorWrapper);

    return platformSpecific.navigatorSetTitleView(this, {
      componentID: this.screenInstanceID+".title"
    });
  }

  setTitle(params = {}) {
    return platformSpecific.navigatorSetTitle(this, params);
  }

  setSubTitle(params = {}) {
    return platformSpecific.navigatorSetSubtitle(this, params);
  }

  setTitleImage(params = {}) {
    return platformSpecific.navigatorSetTitleImage(this, params);
  }

  setStyle(params = {}) {
    if (Platform.OS === 'ios') {
      return platformSpecific.navigatorSetStyle(this, params);
    } else {
      console.log(`Setting style isn\'t supported on ${Platform.OS} yet`);
    }
  }

  toggleDrawer(params = {}) {
    return platformSpecific.navigatorToggleDrawer(this, params);
  }

  toggleTabs(params = {}) {
    return platformSpecific.navigatorToggleTabs(this, params);
  }

  toggleNavBar(params = {}) {
    return platformSpecific.navigatorToggleNavBar(this, params);
  }

  setTabBadge(params = {}) {
    return platformSpecific.navigatorSetTabBadge(this, params);
  }

  switchToTab(params = {}) {
    return platformSpecific.navigatorSwitchToTab(this, params);
  }

  showSnackbar(params = {}) {
    return platformSpecific.showSnackbar(this, params);
  }

  showContextualMenu(params, onButtonPressed) {
    return platformSpecific.showContextualMenu(this, params, onButtonPressed);
  }

  dismissContextualMenu() {
    return platformSpecific.dismissContextualMenu();
  }

  setOnNavigatorEvent(callback) {
    this.navigatorEventHandler = callback;
    if (!this.navigatorEventSubscription) {
      let Emitter = Platform.OS === 'android' ? DeviceEventEmitter : NativeAppEventEmitter;
      this.navigatorEventSubscription = Emitter.addListener(this.navigatorEventID, (event) => this.onNavigatorEvent(event));
      _allNavigatorEventHandlers[this.navigatorEventID] = (event) => this.onNavigatorEvent(event);
    }
  }

  handleDeepLink(params = {}) {
    if (!params.link) return;
    const event = {
      type: 'DeepLink',
      link: params.link
    };
    for (let i in _allNavigatorEventHandlers) {
      _allNavigatorEventHandlers[i](event);
    }
  }

  onNavigatorEvent(event) {
    if (this.navigatorEventHandler) {
      this.navigatorEventHandler(event);
    }
  }

  cleanup() {
    if (this.navigatorEventSubscription) {
      this.navigatorEventSubscription.remove();
      delete _allNavigatorEventHandlers[this.navigatorEventID];
    }
  }
}

export default class Screen extends Component {

  static navigatorStyle = {};
  static navigatorButtons = {};
  static titleRenderFunction = () => {};

  constructor(props) {
    super(props);
    if (props.navigatorID) {
      this.navigator = new Navigator(props.navigatorID, props.navigatorEventID, props.screenInstanceID);
    }
  }

  componentWillUnmount() {
    if (this.navigator) {
      this.navigator.cleanup();
      this.navigator = undefined;
    }
  }
}

/**
 * Wrapper for a render function 
 */
class RenderContainer extends Component {

  render() {
    if (this.props.render) {
      return this.props.render();
    } else {
      return null;
    }
  }
}
