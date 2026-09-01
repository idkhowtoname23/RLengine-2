**What was added in RLengine 2.0 and how it differs from 1.5**

In **RLengine 2.0**, the engine made a full architectural transition from a pseudo-three-dimensional (2.5D) projection to a true 3D space with expanded control and mathematical capabilities.

**Key Additions in RLengine 2.0**

* **Full 3D Camera System (Yaw/Pitch):** Added Euler angles for free camera rotation horizontally and vertically using the mouse (while holding Right Mouse Button).
* **6DOF Free Flight:** Implemented true camera movement in 3D space along look vectors (`WASD` to move along the direction of view, `Space` / `Shift` for ascending and descending along the Y-axis).
* **Volumetric Collision Box:** The bounding box for physics was expanded across all three axes ($1600 \times 1600 \times 1600$ units), creating an enclosed 3D cube instead of flat boundaries.
* **Three-Dimensional Near-Clipping Projection:** Added a $Z_2 > 10$ check that clips particles located behind or too close to the camera lens, preventing visual artifacts.
* **Centralized Gravitational Field:** When clicking LMB, the attraction point is now calculated relative to the center of the 3D coordinate space $(0, 0, 0)$.

---

**Main Differences Between RLengine 2.0 and RLengine 1.5**

| Feature / Specification | RLengine 1.5 (2.5D) | RLengine 2.0 (Full 3D) |
| --- | --- | --- |
| **Z-Axis** | Used only for depth and fog; objects move along a plane | Full spatial axis with true rotation and motion |
| **Camera Rotation** | None (fixed viewing angle) | Full rotation along Pitch and Yaw axes |
| **Movement** | Camera pan restricted to X and Y axes | Free 3D flight movement relative to view direction |
| **Transformation Math** | Simple perspective division (`fov / Z`) | Trigonometric rotation matrices using `sin`/`cos` across two axes |
| **Attraction Point (LMB)** | Bound to 2D screen coordinates of the mouse cursor | Functions as a 3D gravitational attractor at the volume center |
