<div align="center">
	<a href="https://github.com/saucekid/sauceVR"><img src="assets/images/logo.png" alt="sauceVR logo" width="256"></img></a>
	<a href="https://github.com/richie0866/Rostruct/releases/latest"><img src="https://img.shields.io/github/v/release/saucekid/sauceVR?include_prereleases" alt="Latest Release" /></a>
	<br>
	Roblox Universal Full-Body VR
</div>


---
## Install

### To install sauceVR for your script executor, save the `package.lua` file located in this repository to your `scripts/` folder.




## Options

### Options are configurable in the script's UI

## Default Controls:

### `Grip Buttons` ▶︎ *Climb wall / Hold tool / Pick up unanchored part*
### `Right Thumbstick Forward` ▶︎ *Jump* 
### **To open menu, rotate both your hands towards the floor**
<p align="right">(<a href="#top">back to top</a>)</p>

---

## **ROrilla VR**:
Gorilla Tag in Roblox *(Outdated)*
```lua
options = {}

options.HeadScale = 2          -- Headscale of camera (Does not change actual head size)
options.FakeHandsTransparency = 1  -- Transparency of Arm Hitboxes
options.Bubblechat = true      -- Force Bubblechat

options.PointerRange = 10      -- Range you can click buttons with your arm

options.TurnDelay = 0.05       -- Delay in sec. for how fast you can turn left and right
options.TurnAngle = 15         -- Change in angle left/right (degrees)

options.ChatEnabled = true     -- See chat on your left hand in-game
 options.ChatLocalRange = 70   -- Local chat range

loadstring(game:HttpGet("https://raw.githubusercontent.com/saucekid/sauceVR/extra/ROrilla.lua"))();
```

<p align="right">(<a href="#top">back to top</a>)</p>

---
## Credits
`TheNexusAvenger` - [NexusVR](https://github.com/TheNexusAvenger/Nexus-VR-Character-Model)

`richie0866` - [Rostruct](https://github.com/richie0866/Rostruct)

`cl1ents` - Arm Solver

## License

sauceVR is available under the MIT license. See [LICENSE](https://github.com/saucekid/sauceVR/blob/main/LICENSE) for more details.