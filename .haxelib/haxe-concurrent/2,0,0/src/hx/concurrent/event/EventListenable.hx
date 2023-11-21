/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.collection.CopyOnWriteArray;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface EventListenable<EVENT> {

    /**
     * @return false if was subscribed already
     */
    function subscribe(listener:EVENT->Void):Bool;

    /**
     * @return false if was not subscribed
     */
    function unsubscribe(listener:EVENT->Void):Bool;
}


@:abstract
class DefaultEventListenable<EVENT> implements EventListenable<EVENT> {

    var _eventListeners = new CopyOnWriteArray<EVENT->Void>();


    public function subscribe(listener:EVENT->Void):Bool  {
        if (listener == null)
            throw "[listener] must not be null";

        return _eventListeners.addIfAbsent(listener);
    }


    public function unsubscribe(listener:EVENT->Void):Bool {
        if (listener == null)
            throw "[listener] must not be null";

        return _eventListeners.remove(listener);
    }


    function unsubscribeAll():Void {
        _eventListeners.clear();
    }
}
