-- hw-setup: clk=D2=GPIO4, sda=D1=GPIO5
id  = 0
sda = 1
scl = 2

timer0 = 0
timer0_iv = 2000
timer1 = 1
timer1_iv = 500

i2c.setup(id, sda, scl, i2c.SLOW)

-- scan for devices
for i=0,127 do
  i2c.start(id)
  resCode = i2c.address(id, i, i2c.TRANSMITTER)
  i2c.stop(id)
  if resCode == true then print("We have a device on address 0x" .. string.format("%02x", i) .. " (" .. i ..")") end
end
-- from: http://www.esp8266.com/viewtopic.php?f=19&t=771#sthash.KvPQiex9.dpuf

hex_digits={63, 6, 91, 79, 102, 109, 125,7, 127, 111, 119, 124, 57, 94, 121, 113}
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
    wrdata(0x38,0x00,args,hex_digits[2],hex_digits[3],hex_digits[4],hex_digits[5])
    -- 1,2,3,4
end

function testy(args)
    test_args(0x47)
end

function clear_disp()
    wrdata_all(0x38, 0x00, 0x47, 0x00)
end
-- light up segments at this memory position, plus 3 followers
function karak(j)
    wrdata(0x38, 0x00, 0x47, j, j+1, j+2, j+3)
end

function dance(count)
    for i=0,count do
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

function intarray(digit)
    buffer = tostring(digit)
    len=string.len(buffer)
    data = {}

    m=digit
    for i=1,len do
        if  (m%10>0) then
          table.insert(data,1,m%10)
          -- 1 means insert as first element
        elseif m>9 then
          -- 10 or bigger means add a "0"
          table.insert(data,1,0)
        else
          -- smaller than 10 means last digit
          table.insert(data,1,m)
        end

        m=m/10
    end

    table.foreachi(data,print)

    return data
end

function printdigits(number)
    tmr.stop(timer0)
    digits = intarray(number)
    str_digits = {}

    for i=1,table.getn(digits) do
        table.insert(str_digits,i,hex_digits[digits[i]+1])
        -- +1 in every case as the arrays (=tables) start at 1, not 0,
        -- but the "0" digit is at position 1 of hex_digits
    end

    -- if there are less than 4 digits, fill in blanks
    for i=table.getn(str_digits),3 do
        table.insert(str_digits,0x00)
    end
    digits = {}
    -- free the array

    count=table.getn(str_digits)-3

    -- start tmr_digit at i=1
    tmr_digit(1,count,str_digits)

    tmr.start(timer0)

end

--this cycles through str_digits
function tmr_digit(i,count, str_digits)
  tmr.alarm(timer1, timer1_iv, tmr.ALARM_SINGLE, function ()
      print("tmr1 activated")
      j=i+1
      print("i+1",j)
      print("str_digits[i+1] == ",str_digits[i+1])
      wrdata(0x38,0x00,0x47,str_digits[i],str_digits[i+1],str_digits[i+2],str_digits[i+3])
      -- +1 more for every right digit to adress the next one
      -- if there are only 4 digits, the timer doesn't get used more than once

      -- if i<count start over at the next position
      if i<count then
          tmr_digit(i+1,count,str_digits)
      end

      end)
end

-- turns segment on at val, puts out val, alternates
function valinfo(val)
    clear_disp()
    tmr.alarm(timer0, timer0_iv, 1, function ()
        print("tmr0 activated")
        if value then
            print("disp 4 characters at the given pos")
            karak(val)
        else
            print("disp the pos")
            printdigits(val)
        end
        value = not value
    end)
end
