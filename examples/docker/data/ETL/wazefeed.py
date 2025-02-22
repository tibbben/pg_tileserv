#!/usr/bin/env python3

import json
import sys

path = sys.argv[1]
filename = sys.argv[2]

with open(path+'/'+filename, encoding='utf-8') as fh:
    waze = json.load(fh)

layers = {
        "alerts": [],
        "jams": ["segments"],
        "irregularities": ["causeAlert","alerts"]
}

for layer,tostring in layers.items():
    if layer in waze:
        geojson = {
            "type": "FeatureCollection",
            "features": []
        }
        for event in waze[layer]:
            if layer == "alerts":
                geom = "Point"
                coords = [event['location']['x'],event['location']['y']]
            else:
                geom = "LineString"
                coords = []
                for pair in event['line']:
                    coords.append([pair['x'],pair['y']])
            properties = {}
            for key,val in event.items():
                if (key not in ['location','line']):
                    if key in tostring: # convert json objects to strings
                        val = json.dumps(val)
                    properties[key] = val
            feature = {
                "type": "Feature",
                "geometry": {
                    "type": geom,
                    "coordinates": coords
                },
                "properties": properties
            }
            geojson["features"].append(feature)
        f = open(path+"/"+layer+".json", "w")
        f.write(json.dumps(geojson))
        f.close()

