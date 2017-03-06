-- hw-setup: clk=D2=GPIO4, sda=D1=GPIO5
id  = 0
sda = 1
scl = 2

-- timer ids & intervals (iv) in ms
timer0 = 0
timer0_iv = 2000
timer1 = 1
timer1_iv = 500

i2c.setup(id, sda, scl, i2c.SLOW)

-- scan for devices
-- http://www.esp8266.com/viewtopic.php?f=19&t=771#sthash.KvPQiex9.dpuf
for i=0,127 do
  i2c.start(id)
  resCode = i2c.address(id, i, i2c.TRANSMITTER)
  i2c.stop(id)
  if resCode == true then print("We have a device on address 0x" .. string.format("%02x", i) .. " (" .. i ..")") end
end

hex_digits={63, 6, 91, 79, 102, 109, 125,7, 127, 111, 119, 124, 57, 94, 121, 113}
-- 0 to 9 (1-10), then A to F (11-16)
-- http://tronixstuff.com/2011/07/21/tutorial-arduino-and-the-nxp-saa1064-4-digit-led-display-driver/
-- http://www.rapidtables.com/convert/number/binary-to-hex.htm

-- alphabet like in http://www.twyman.org.uk/Fonts/
alph = {119, 124, 57, 94, 121, 113, 111, 118, 6, 30, 118, 56, 21, 84, 63, 115, 103, 80, 109, 120, 62, 28, 42, 118, 110, 91}
--       A,   B,  C,   D, E,   F,    G,  H, I=1,  J, K=H, L,  M, N,  O=0, P,   Q,   R, S=5,  T,  U,   V,  W, X=H,   Y, Z=2
-- small_h=116, big_G=61, mirror_F=71, small_o=92
dash = 64
degree = 99
lightning = 100
questionmark = 83
underscore = 8
-- reverse_lightning=82,II=54, equals=65/72, two_bars=9, gamma=51, xi=73


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

-- run wrdata with defaults
function wrdata_def(digitsa, digitsb, digitsc, digitsd)
    wrdata(0x38, 0x00, 0x47, digitsa, digitsb, digitsc, digitsd)
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

-- light up segments at this mapping position plus 3 following map. pos.
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

-- helper for printdigits: turn an int into an array
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

    -- print table debug fct
    -- table.foreachi(data,print)

    return data
end

-- print more than 4 digits by shifting left (caution: can't take larger than integer arg)
function printdigits(number)
    -- first, disable the alternating timer from top-level of valinfo
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

--cycle through str_digits with timer1
function tmr_digit(i,count, str_digits)
  tmr.alarm(timer1, timer1_iv, tmr.ALARM_SINGLE, function ()

      j=i+1
      wrdata(0x38,0x00,0x47,str_digits[i],str_digits[i+1],str_digits[i+2],str_digits[i+3])
      -- +1 more for every right digit to adress the next one
      -- if there are only 4 digits, the timer doesn't get used more than once

      -- if i<count start over at the next position
      if i<count then
          tmr_digit(i+1,count,str_digits)
      end

      end)
end

-- alternate between karak and printdigit of karak's argument
function valinfo(val)
    clear_disp()
    tmr.alarm(timer0, timer0_iv, 1, function ()

        if value then
            -- display 4 characters at the given pos
            karak(val)
        else
            -- display the pos
            printdigits(val)
        end
        value = not value
    end)
end

-- run a charakter array around continuously
function loopy(arry)
    clear_disp()
    len = table.getn(arry)
    i = 1

    tmr.alarm(timer0, timer0_iv, 1, function ()
        wrdata_def(arry[i],arry[i+1],arry[i+2],arry[i+3])
        if i <(len-3) then
            i = i +1
        else
            i=1
        end

    end)
end

-- run a snake made from characters around continuously
function snake(head, body, tail, blank)
    clear_disp()
    snake = {blank, blank, blank, head, body, body, tail, blank, blank, blank, blank}
    loopy(snake)
end

-- example snake
function snake_def()
    snake(42, hex_digits[1],hex_digits[1],0)
end

-- loop seamlessly
function loopy_s(array)
    table.insert(array,array[1])
    table.insert(array,array[2])
    table.insert(array,array[3])
    loopy(array)
end

-- loop the alphabet
function run_alph()
    loopy_s(alph)
end

-- turn text into the corresponding characters
function text_to_c_array(str)
  arry={}

  str=string.upper(str)

  -- for each string character find the mapped segment-character
  for i=1,string.len(str) do
      ascii = string.byte (str, i)
      -- 20 is space (space-bar)
      -- 48-57 is 0-9
      -- 65-90 is A-Z

      if (ascii>47 and ascii<58) then
          table.insert(arry,hex_digits[ascii-47])

      elseif (ascii>64 and ascii<91) then
          table.insert(arry,alph[ascii-64])
          -- 65 = "A" --> index "1"
      else
           -- insert blank character
           table.insert(arry,0)
      end
  end


  return arry

end

function output_text(str)
  arry={}
  arry=text_to_c_array(str)

  -- insert blank characters at start and end
  table.insert(arry,1,0)
  table.insert(arry,0)
  loopy_s(arry)
end
