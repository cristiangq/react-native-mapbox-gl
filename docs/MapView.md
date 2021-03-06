## <MapboxGL.MapView />
### MapView backed by Mapbox Native GL

### props
| Prop | Type | Default | Required | Description |
| ---- | :--: | :-----: | :------: | :----------: |
| animated | `bool` | `false` | `false` | Animates changes between pitch and bearing |
| centerCoordinate | `arrayOf` | `none` | `false` | Initial center coordinate on map [lng, lat] |
| showUserLocation | `bool` | `none` | `false` | Shows the users location on the map |
| userTrackingMode | `number` | `MapboxGL.UserTrackingModes.None` | `false` | The mode used to track the user location on the map |
| contentInset | `union` | `none` | `false` | The distance from the edges of the map view’s frame to the edges of the map view’s logical viewport. |
| heading | `number` | `0` | `false` | Initial heading on map |
| pitch | `number` | `0` | `false` | Initial pitch on map |
| style | `any` | `none` | `false` | Style for wrapping React Native View |
| styleURL | `string` | `MapboxGL.StyleURL.Street` | `false` | Style URL for map |
| zoomLevel | `number` | `16` | `false` | Initial zoom level of map |
| minZoomLevel | `number` | `none` | `false` | Min zoom level of map |
| maxZoomLevel | `number` | `none` | `false` | Max zoom level of map |
| scrollEnabled | `bool` | `true` | `false` | Enable/Disable scroll on the map |
| pitchEnabled | `bool` | `true` | `false` | Enable/Disable pitch on map |
| rotateEnabled | `bool` | `true` | `false` | Enable/Disable rotation on map |
| attributionEnabled | `bool` | `true` | `false` | Enable/Disable attribution on map. For iOS you need to add MGLMapboxMetricsEnabledSettingShownInApp=YES<br/>to your Info.plist |
| logoEnabled | `bool` | `true` | `false` | Enable/Disable the logo on the map. |
| compassEnabled | `bool` | `none` | `false` | Enable/Disable the compass from appearing on the map |
| onPress | `func` | `none` | `false` | Map press listener, gets called when a user presses the map |
| onLongPress | `func` | `none` | `false` | Map long press listener, gets called when a user long presses the map |
| onRegionWillChange | `func` | `none` | `false` | This event is triggered whenever the currently displayed map region is about to change. |
| onRegionIsChanging | `func` | `none` | `false` | This event is triggered whenever the currently displayed map region is changing. |
| onRegionDidChange | `func` | `none` | `false` | This event is triggered whenever the currently displayed map region finished changing |
| onWillStartLoadingMap | `func` | `none` | `false` | This event is triggered when the map is about to start loading a new map style. |
| onDidFinishLoadingMap | `func` | `none` | `false` | This is triggered when the map has successfully loaded a new map style. |
| onDidFailLoadingMap | `func` | `none` | `false` | This event is triggered when the map has failed to load a new map style. |
| onWillStartRenderingFrame | `func` | `none` | `false` | This event is triggered when the map will start rendering a frame. |
| onDidFinishRenderingFrame | `func` | `none` | `false` | This event is triggered when the map finished rendering a frame. |
| onDidFinishRenderingFrameFully | `func` | `none` | `false` | This event is triggered when the map fully finished rendering a frame. |
| onWillStartRenderingMap | `func` | `none` | `false` | This event is triggered when the map will start rendering the map. |
| onDidFinishRenderingMap | `func` | `none` | `false` | This event is triggered when the map finished rendering the map. |
| onDidFinishRenderingMapFully | `func` | `none` | `false` | This event is triggered when the map fully finished rendering the map. |
| onDidFinishLoadingStyle | `func` | `none` | `false` | This event is triggered when a style has finished loading. |
| onFlyToComplete | `func` | `none` | `false` | This event is triggered when a fly to animation is cancelled or completed after calling flyTo |
| onSetCameraComplete | `func` | `none` | `false` | This event is triggered once the camera is finished after calling setCamera |

### methods
#### getVisibleBounds()

The coordinate bounds(ne, sw) visible in the users’s viewport.

##### arguments
| Name | Type | Required | Description  |
| ---- | :--: | :------: | :----------: |




```javascript
const visibleBounds = await this._map.getVisibleBounds();
```


#### queryRenderedFeaturesAtPoint(coordinate[, filter][, layerIDs])

Returns an array of rendered map features that intersect with a given point.

##### arguments
| Name | Type | Required | Description  |
| ---- | :--: | :------: | :----------: |
| `coordinate` | `Array` | `Yes` | A point expressed in the map view’s coordinate system. |
| `filter` | `Array` | `No` | A set of strings that correspond to the names of layers defined in the current style. Only the features contained in these layers are included in the returned array. |
| `layerIDs` | `Array` | `No` | A array of layer id's to filter the features by |



```javascript
this._map.queryRenderedFeaturesAtPoint([30, 40], ['==', 'type', 'Point'], ['id1', 'id2'])
```


#### queryRenderedFeaturesInRect(bbox[, filter][, layerIDs])

Returns an array of rendered map features that intersect with the given rectangle,<br/>restricted to the given style layers and filtered by the given predicate.

##### arguments
| Name | Type | Required | Description  |
| ---- | :--: | :------: | :----------: |
| `bbox` | `Array` | `Yes` | A rectangle expressed in the map view’s coordinate system. |
| `filter` | `Array` | `No` | A set of strings that correspond to the names of layers defined in the current style. Only the features contained in these layers are included in the returned array. |
| `layerIDs` | `Array` | `No` |  A array of layer id's to filter the features by |



```javascript
this._map.queryRenderedFeaturesInRect([30, 40, 20, 10], ['==', 'type', 'Point'], ['id1', 'id2'])
```


#### fitBounds(northEastCoordinates, southWestCoordinates[, padding][, duration])

Map camera transitions to fit provided bounds

##### arguments
| Name | Type | Required | Description  |
| ---- | :--: | :------: | :----------: |
| `northEastCoordinates` | `Array` | `Yes` | North east coordinate of bound |
| `southWestCoordinates` | `Array` | `Yes` | South west coordinate of bound |
| `padding` | `Number` | `No` | Camera padding for bound |
| `duration` | `Number` | `No` | Duration of camera animation |



```javascript
this.map.fitBounds([lng, lat], [lng, lat])
this.map.fitBounds([lng, lat], [lng, lat], 20, 1000) // padding for all sides
this.map.fitBounds([lng, lat], [lng, lat], [verticalPadding, horizontalPadding], 1000)
this.map.fitBounds([lng, lat], [lng, lat], [top, right, bottom, left], 1000)
```


#### flyTo(coordinates[, duration])

Map camera will fly to new coordinate

##### arguments
| Name | Type | Required | Description  |
| ---- | :--: | :------: | :----------: |
| `coordinates` | `Array` | `Yes` | Coordinates that map camera will jump too |
| `duration` | `Number` | `No` | Duration of camera animation |



```javascript
this.map.flyTo([lng, lat])
this.map.flyTo([lng, lat], 12000)
```


#### moveTo(coordinates[, duration])

Map camera will move to new coordinate at the same zoom level

##### arguments
| Name | Type | Required | Description  |
| ---- | :--: | :------: | :----------: |
| `coordinates` | `Array` | `Yes` | Coordinates that map camera will move too |
| `duration` | `Number` | `No` | Duration of camera animation |



```javascript
this.map.moveTo([lng, lat], 200) // eases camera to new location based on duration
this.map.moveTo([lng, lat]) // snaps camera to new location without any easing
```


#### zoomTo(zoomLevel[, duration])

Map camera will zoom to specified level

##### arguments
| Name | Type | Required | Description  |
| ---- | :--: | :------: | :----------: |
| `zoomLevel` | `Number` | `Yes` | Zoom level that the map camera will animate too |
| `duration` | `Number` | `No` | Duration of camera animation |



```javascript
this.map.zoomTo(16)
this.map.zoomTo(16, 100)
```


#### setCamera(config)

Map camera will perform updates based on provided config. Advanced use only!

##### arguments
| Name | Type | Required | Description  |
| ---- | :--: | :------: | :----------: |
| `config` | `Object` | `Yes` | Camera configuration |



```javascript
this.map.setCamera({
  centerCoordinate: [lng, lat],
  zoomLevel: 16,
  duration: 2000,
})

this.map.setCamera({
  stops: [
    { pitch: 45, duration: 200 },
    { heading: 180, duration: 300 },
  ]
})
```



