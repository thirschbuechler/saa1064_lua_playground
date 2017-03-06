Found a Humax Btci-5900 frontpanel with a saa1064 (i2c) led segment driver in the basement, might as well play with it a little.





#Installation (Linux-syntax):

Write the file to a nodemcu V2:
`sudo ./luatool.py --port /dev/ttyUSB0 --src humax_saa1064.lua --dest init.lua --verbose --baud 115200`
(alternatively, it could be written to another dest (e.g. --dest humax_saa1064.lua) than init.lua and called via `dofile("humax_saa1064.lua")`. Especially if you don't want to change the functions, just call them, and use the file as a library, this will save time)

open a serial terminal (defaults to `/dev/ttyUSB0`):
`sudo gtkterm -s 115200
`
toggle a restart via hitting F7 twice,
a prompt (">") should appear


(Be sure to not have a print-loop at startup, since you may not be able to write new files without exiting the loop. This might require a re-flash with esptool.py .. just sayin'..)

(For viewing and editing I prefer to use Atom, with the `lua-language` package installed: (webupd8 Atom repo)[1]  and `apm install lua-language` )

[1]:https://launchpad.net/~webupd8team/+archive/ubuntu/atom

#I2C-notes
If you're struggling with i2c in lua on your nodemcu, take a look at how wrdata is implemented:
![alt-tag](wrdata_bits.png)
```lua
function wrdata(adr, data1, data2, digitsa, digitsb, digitsc, digitsd)
    i2c.start(id)
    i2c.address(id, adr, i2c.TRANSMITTER)
    i2c.write(id, data1)
    i2c.write(id, data2)
    i2c.write(id, digitsa)
    i2c.write(id, digitsb)
    i2c.write(id, digitsc)
    i2c.write(id, digitsd)
    i2c.stop(id)
end
```

Also: Addressing is 7bit only (like on arduino: the LSB of the 8bit adr. gets cut), ACKs don't have to be catched.
