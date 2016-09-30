/**
 * Created by ltjin on 16/9/19.
 */
import React, { Component } from 'react';
import { requireNativeComponent } from 'react-native';

var IM = requireNativeComponent('RCTIM', IMView);

export default class IMView extends Component {

    static propTypes = {
        control: React.PropTypes.string,
        callInfo: React.PropTypes.object.isRequired,
        onHangUp: React.PropTypes.func
    }

    render() {
        return <IM {...this.props}/>;
    }
}