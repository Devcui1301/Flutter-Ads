package com.vuongdv.admob_ads

open class CollapsibleAdActionCallback {
    open fun call(type: String, data: Any? = null) {}

    open fun pauseCollapsibleAdLoad() {}

    open fun resumeCollapsibleAdLoad() {}
}