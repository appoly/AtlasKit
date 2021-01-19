# AtlasKit
A swift library for quickly integrating a location search in your app.
 
**Installing with cocoapods**
```
pod 'AtlasKit'
```

**Quick start**

First start by creating a `AtlasKit` object with a datasource: Apple, Google or GetAddress.io. An AtlasKit instance with an apple datasource will try to use Apple Maps to get locations, whereas one with a Google or GetAddress datasource will take an API key when initializing and try to make use of the respective API ( Google Places or GetAddress).

Once you have your instance setup you can begin making search requests, you can do this with or without a delay (for use with textfields that search as you type).

```
atlasKit.performSearchWithDelay(term, delay: 0.5) { predictions, error in
    ...
}

atlasKit.performSearch(term) { { predictions, error in
    ...
}
```

You can also cancel all pending searches with;
```
atlasKit.cancelSearch()
```

Search predictions are instances of the `AtlasKitPlace` object, which consists of; a street address, a city, a postcode, a state, a country, a location (coordinates). Be aware that each of these values are optional and may not always be available.

**Warning - this library was only intended to be used for UK locations, as a result the postcode value is not supported outside of the UK.**
