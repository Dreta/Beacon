# Outline of Planned Features

* Navigation
  * Integrate with map APIs - to be done later
  * When the user puts down their phone, enter navigation mode. When the user raise their phone, enter obstacle detection mode.
  * But also allow the user to only use obstacle detection mode.
* Obstacle Detection
  * Detect obstacles and their distances with a live camera view.
  * Several feedback methods for obstacles (can be enabled simultaneously)
    * Use haptic feedback to alert the user of obstacles - quicker vibrations for closer obstacles, slower vibrations for farther obstacles (Choose one between audio and haptic).
    * Use audio feedback to alert the user of obstacles - louder sounds for closer obstacles, quieter sounds for farther obstacles (Choose one between audio and haptic).
    * Voice feedback to tell the user the type of obstacle (Separately enabled).
  * Issues?
    * Objects in front but at a lower position might not be seen. (Can you save their distances beforehand, but invalidate after time or user turning?)
