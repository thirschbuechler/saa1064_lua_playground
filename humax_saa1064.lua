-- hw-setup: clk=D2=GPIO4, sda=D1=GPIO5
id  = 0
sda = 1
scl = 2

i2c.setup(id, sda, scl, i2c.SLOW)

-- scan for devices
for i=0,127 do
  i2c.start(id)
  resCode = i2c.address(id, i, i2c.TRANSMITTER)
  i2c.stop(id)
  if resCode == true then print("We have a device on address 0x" .. string.format("%02x", i) .. " (" .. i ..")") end
end
-- from: http://www.esp8266.com/viewtopic.php?f=19&t=771#sthash.KvPQiex9.dpuf


digits={63, 6, 91, 79, 102, 109, 125,7, 127, 111, 119, 124, 57, 94, 121, 113}
-- 0 to 9 (1-10), then A to F (11-16)
-- http://tronixstuff.com/2011/07/21/tutorial-arduino-and-the-nxp-saa1064-4-digit-led-display-driver/
-- http://www.rapidtables.com/convert/number/binary-to-hex.htm

-- todo: alphabet like in http://www.twyman.org.uk/Fonts/
-- M = 21

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

function wrdata_all(adr, data1, data2, digits)
    wrdata(adr, data1, data2, digits, digits, digits, digits)
end

function test_args(args)
    wrdata(0x38,0x00,args,digits[2],digits[3],digits[4],digits[5])
    -- 1,2,3,4
end

function testy(args)
    test_args(0x47)
end

function karak(j)
    wrdata(0x38, 0x00, 0x47, j, j+1, j+2, j+3)
end

function dance(untils)
    for i=0,untils do
      wrdata_all(0x38, 0x00, 0x47, i)
      print(i)
      tmr.delay(1000)
      -- halt for 1000 us : warning: may affect network stack
      -- also see https://github.com/nodemcu/nodemcu-firmware/blob/master/docs/en/modules/tmr.md
    end
end

function go_dance()
    dance(127)
end
