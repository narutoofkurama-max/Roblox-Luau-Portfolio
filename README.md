# Roblox Luau Portfolio

Selected Roblox/Luau scripting work from personal development projects. These samples are presented as code-focused portfolio pieces rather than complete games or downloadable projects.

## Skills demonstrated

- Client/server separation with RemoteEvents
- Server-authoritative gameplay and ownership checks
- Luau event-driven state management
- DataStore integration for first-visit state
- Gameplay cooldowns and request validation
- Spatial queries, raycasts, waypoint movement, and targeting
- Runtime EditableMesh reconstruction and caching
- Programmatic UI, responsive scaling, and tweened presentation
- Vehicle handling integration and frame-based interpolation

## Vehicle systems

### Runtime vehicle mesh restoration

`vehicle-systems/VehicleMeshLoader.client.luau` reconstructs locally authored vehicle meshes from chunked JSON data stored in `ReplicatedStorage`. It caches generated mesh templates, rebuilds editable geometry incrementally, applies meshes to runtime `MeshPart` instances, and exposes load/error state through player attributes.

Technical features include `AssetService` EditableMesh APIs, JSON decoding, template caching, weak-key tracking, incremental yielding, collision-fidelity selection, and protected per-part restoration.

Dependency: Roblox EditableMesh APIs and the project-specific `VehicleMeshRuntimeData` format. Mesh data and vehicle assets are intentionally not included.

### Driving comfort controller

`vehicle-systems/VehicleDrivingComfort.client.luau` manages the local driving experience around an A-Chassis vehicle hierarchy. It disables jumping while seated, restores wheel properties when leaving, interpolates handbrake grip, and applies speed-sensitive camera FOV.

Dependency: A-Chassis runtime object names and the `A-Chassis Interface` UI values. A-Chassis source is third-party and is not included.

## Tower-defense systems

### Server wave and turret manager

`tower-defense/WaveManager.server.luau` runs configurable enemy waves, moves enemies through ordered waypoints, maintains health bars, validates turret placement on the server, aims turrets at nearby enemies, and fires temporary projectiles.

The server owns wave state, enemy damage, turret creation, placement validation, and targeting. Placement requests are type-checked, throttled, distance-limited, and rejected when they overlap paths or existing turrets.

Dependencies: the project’s `ReplicatedStorage` templates/remotes and `Workspace` folders such as `SpawnPart`, `Waypoints`, `Turrets`, and path parts. The sample still uses the source project’s simple combat model and does not claim to be a complete economy or progression system.

### Client wave and turret controller

`tower-defense/WaveController.client.luau` provides the turret ghost preview, raycast hover state, placement-mode lifecycle, button input, wave banners, denial feedback, and tweened notifications.

The client is responsible for presentation and input only; the server remains authoritative over placement. It depends on the `WaveGui` hierarchy and the same remotes/templates as `WaveManager`.

## Progression and economy

### Tomato plot and economy server

`progression-economy/TomatoStarterServer.server.luau` assigns players to plots, enforces plot ownership, creates a cash leaderstat, handles stand purchases and upgrades, rate-limits sales and touch interactions, manages visual stage progression, assigns respawns, animates the stand, and records first-visit tutorial state through `DataStoreService`.

This demonstrates server-authoritative progression, ownership validation, state attributes, cooldowns, and persistence-aware onboarding. Cash and upgrade state are intentionally not persisted in this sample, so it should be read as a focused system rather than a complete save architecture.

Dependencies: `TomatoMap.Plots`, the plot child controls/models, `ReplicatedStorage.TomatoTutorialEvent`, and the `TomatoFirstVisit_v1` DataStore name from the original project.

### Tomato HUD and tutorial client

`progression-economy/TomatoStarterClient.client.luau` builds a cash HUD, tutorial messaging, a first-visit letter, an animated starter note, responsive letter scaling, and client-only affordability coloring for plot controls.

This demonstrates programmatic UI construction, tween sequencing, viewport-aware layout, attribute observation, and presentation driven by server state. It does not award currency or make purchase decisions.

## Authenticity and dependencies

These are selected code samples extracted from personal development projects. They are not claimed to be released games or client commissions. Third-party A-Chassis source, generated mesh data, decorative assets, and other non-code project content are excluded. No secrets, API keys, tokens, webhooks, private URLs, or personal information were found in the selected samples.

## Remaining limitations

- The vehicle samples depend on project-specific runtime hierarchies.
- The tower-defense sample has no player currency or ownership system for turrets.
- The tomato sample does not persist cash or upgrade progression.
- The samples were organized for code review; they were not redesigned into standalone packages.