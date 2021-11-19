<div align="center">
	<a href="https://github.com/saucekid/sauceVR"><img src="assets/images/logo.png" alt="sauceVR logo" width="256"></img></a>
	<a href="https://github.com/richie0866/Rostruct/releases/latest"><img src="https://img.shields.io/github/v/release/saucekid/sauceVR?include_prereleases" alt="Latest Release" /></a>
	<br>
	Universal R6/R15 Full-Body VR
</div>


---

## Script


```lua
getgenv().options = {
    --Bodyslots or Default (Bodyslots is buggy and)
    Inventory = "Bodyslots" ,
    
    --None, SmoothLocomotion, or teleport (These can be changed in settings)
    DefaultMovementMethod = "None",
    
    --None, SmoothLocomotion, or teleport (These can be changed in settings)
    DefaultCameraOption = "Default",
    
--==[Advanced Options]
    --Character Transparency in First Person
    LocalCharacterTransparency = 0.5,

    --Maximum angle the neck can turn before the torso turns.
    MaxNeckRotation = math.rad(35),
    MaxNeckSeatedRotation = math.rad(60),
    
    --Maximum angle the neck can tilt before the torso tilts.
    MaxNeckTilt = math.rad(60),
    
    --Maximum angle the center of the torso can bend.
    MaxTorsoBend = math.rad(10),
    
    --Inventory Slot Positions (Relative to HumanoidRootPart)
    InventorySlots = { 
        [1] = CFrame.new(-1,-.25,0) * CFrame.Angles(0,math.rad(0),0),
        [2] = CFrame.new(1,-.25,0) * CFrame.Angles(0,math.rad(90),0),
        [3] = CFrame.new(0,0,.5) * CFrame.Angles(0,math.rad(90),0),
    },
        
    --Velocity of part (more = more jitter, but more stable)
    NetlessVelocity = Vector3.new(0,-45,0)
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/saucekid/sauceVR/main.lua"))();
```

## Default Controls:

### `Grip Buttons` ▶︎ *Climb Wall/Hold Tool/Hold Unanchored Part*
### `A` ▶︎ *Jump Button* ***(Customizable)***
### **To open menu, rotate both your hands towards the floor**
<p align="right">(<a href="#top">back to top</a>)</p>

---

## **ROrilla VR**:
Gorilla Tag in Roblox
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
`TheNexusAvenger` - *NexusVR*

## License

sauceVR is available under the MIT license. See [LICENSE](https://github.com/saucekid/sauceVR/blob/main/LICENSE) for more details.