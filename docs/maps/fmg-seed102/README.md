# Generated world map (experiment)

A world map for the game made with Azgaar's Fantasy Map Generator (MIT licence; maps made with it are ours to use), seed 102 (`archipelago` template), with the game's own geography placed on it.

- `game-map.png`: the map at 3200×2000.
- `game-map.svg`: the same map as a vector image (the generator's full SVG with a `gameLayer` group on top).
- `game-map-data.json`: everything in map pixels (1600×1000): `places` (every landmark id from `world_map.dart`, including the city districts clustered around Alster, Saltmouth and the Black Reliquary), `lands` (the three continents' coastlines), the 12 longest `rivers`, `roads` (every road of `world_roads.dart` routed over the terrain; sea and sky roads marked `sea`), and `why` (the biome, height, coast and river of the spot each landmark got).

## How the game's world was placed

- The Old Continent is the largest island: it has the generator's desert (the Waste) and temperate land with a river (Alster).
- The Ashen Continent is the island with taiga and tundra (the Frost Reach) and wetland (the Grey Fen).
- The Lantern Isles are the third island (Candlehold).
- One anchor place per country is picked first, far from the others. The island is then split between those anchors, and each country's other places stay in its own share, chosen by biome, coast, river and height.
- Land roads follow the cheapest way over the land (hills cost more). Sea roads follow open water. The Lark's flight from Alster's quay is a straight dashed line.

## Reproducing it

The website is blocked from the cloud sessions, so the generator runs from its source:

```
git clone --depth 1 https://github.com/Azgaar/Fantasy-Map-Generator.git fmg
cd fmg && ELECTRON_SKIP_BINARY_DOWNLOAD=1 npm install --ignore-scripts && npx vite --port 5173 &
cd scripts && (printf 'const SPEC = '; cat spec.json; printf ';\n'; cat build.js) > build-run.js
node run.cjs <path-to-fmg> 102 build-run.js out
```

`search.cjs` scores other seeds for a world with the right shapes and climates.

## Not done yet

- Nothing in the game uses this map. Making it a fourth chart geography in `chart_worlds.dart` means scaling `places`, `lands` and `rivers` to the chart's coordinates (Core).
- It's in the generator's atlas style, not the game's pixel style (UX).
