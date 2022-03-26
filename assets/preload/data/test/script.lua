

--Example script for some stuff


----Modcharting setup

p1DefX = {0,0,0,0,0,0,0,0,0}
p2DefX = {0,0,0,0,0,0,0,0,0}

p1DefY = {0,0,0,0,0,0,0,0,0}
p2DefY = {0,0,0,0,0,0,0,0,0}

p1strums = {};
p2strums = {};
p1curMania = 4;
p2curMania = 4;

p1curScale = 0;
p1curWidth = 0;

p2curScale = 0;
p2curWidth = 0;

function onEvent(name, value1, value2) --dumb system that allows you to transfer note values over to other scripts
                                        
	if name == 'getP1Mania' then 
        p1curMania = value1
    elseif name == 'getP1Width' then 
        p1curWidth = value1
    elseif name == 'getP1Scale' then 
        p1curScale = value1
    elseif name == 'getP1DefPos0' then 
        p1DefX[1] = value1
        p1DefY[1] = value2
    elseif name == 'getP1DefPos1' then 
        p1DefX[2] = value1
        p1DefY[2] = value2
    elseif name == 'getP1DefPos2' then 
        p1DefX[3] = value1
        p1DefY[3] = value2
    elseif name == 'getP1DefPos3' then 
        p1DefX[4] = value1
        p1DefY[4] = value2
    elseif name == 'getP1DefPos4' then 
        p1DefX[5] = value1
        p1DefY[5] = value2
    elseif name == 'getP1DefPos5' then 
        p1DefX[6] = value1
        p1DefY[6] = value2
    elseif name == 'getP1DefPos6' then 
        p1DefX[7] = value1
        p1DefY[7] = value2
    elseif name == 'getP1DefPos7' then 
        p1DefX[8] = value1
        p1DefY[8] = value2
    elseif name == 'getP1DefPos8' then 
        p1DefX[9] = value1
        p1DefY[9] = value2

    elseif name == 'getP2Mania' then 
        p2curMania = value1
    elseif name == 'getP2Width' then 
        p2curWidth = value1
    elseif name == 'getP2Scale' then 
        p2curScale = value1
    elseif name == 'getP2DefPos0' then 
        p2DefX[1] = value1
        p2DefY[1] = value2
    elseif name == 'getP2DefPos1' then 
        p2DefX[2] = value1
        p2DefY[2] = value2
    elseif name == 'getP2DefPos2' then 
        p2DefX[3] = value1
        p2DefY[3] = value2
    elseif name == 'getP2DefPos3' then 
        p2DefX[4] = value1
        p2DefY[4] = value2
    elseif name == 'getP2DefPos4' then 
        p2DefX[5] = value1
        p2DefY[5] = value2
    elseif name == 'getP2DefPos5' then 
        p2DefX[6] = value1
        p2DefY[6] = value2
    elseif name == 'getP2DefPos6' then 
        p2DefX[7] = value1
        p2DefY[7] = value2
    elseif name == 'getP2DefPos7' then 
        p2DefX[8] = value1
        p2DefY[8] = value2
    elseif name == 'getP2DefPos8' then 
        p2DefX[9] = value1
        p2DefY[9] = value2
	end
end

function onSongStart()
    triggerEvent('Update Strum Values',0,0)
end

------- end of modcharting setup, copy all this into a script to be able to access values to modchart



function onCreatePost()
    triggerEvent('Activate extra keys', 6) --starts song with 6k
end


doFunkyShit = false --disabled rn, just change it if you want it to work

function onUpdate(elapsed) -- this code is the one from detected where the notes spin and it move up and down, idc if anyone wants to use this code

    local currentBeat = (getSongPosition() / 1000)*(bpm/60);
    
    if doFunkyShit then 
        for i = 0,8 do 
            local xpos = 0
            local ypos = 0
    
            xpos = xpos + (32 * math.sin((currentBeat + i*0.25) * math.pi)); 
            local mu = -1;
            if (i % 2 == 0) then 
                mu = 1;
            end
            ypos = ypos + (32 * mu * math.tan((currentBeat) * 0.25 * math.pi));
    
            setProperty(i..'.x', p2DefX[i + 1] + xpos)
            setProperty(i..'.y', p2DefY[i + 1] + ypos)
        end
    
        for i = 9,17 do 
            local xpos = 0
            local ypos = 0
    
            xpos = xpos + (32 * math.sin((currentBeat + (i - 9)*0.25) * math.pi)); 
            local mu = -1;
            if ((i - 9) % 2 == 0) then 
                mu = 1;
            end
            ypos = ypos + (32 * mu * math.tan((currentBeat) * 0.25 * math.pi));
    
            setProperty(i..'.x', p1DefX[i + 1 - 9] + xpos) -- do -9 to get correct index for playerstrums
            setProperty(i..'.y', p1DefY[i + 1 - 9] + ypos)
        end
    end


end

local hasSpun = false

function onBeatHit()

    if doFunkyShit then 

        if curBeat % 4 == 0 then 
            for i = 0,17 do --spin stuff, just do all
                if hasSpun then 
                    setProperty(i..'.angle', -360)
                else 
                    setProperty(i..'.angle', 360)
                end
                doTweenAngle(i..'spin', i, 0, (stepCrochet / 1000) * 8, 'cubeOut')
            end
        end
    end

end


