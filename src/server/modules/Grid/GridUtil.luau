local DEFAULT_RAY_LENGTH = 1000

local GridUtil = {}

function GridUtil.pointToWorldCf(anchor: CFrame, cellSize: Vector2, pos: Vector2): CFrame
    return anchor * CFrame.new((pos.X - 1) * cellSize.X, 0, (pos.Y - 1) * cellSize.Y)
end

function GridUtil.castRayToGround(target: CFrame, raycastParams: RaycastParams, height: number?): RaycastResult?
    local rayLength = height or DEFAULT_RAY_LENGTH
    
    local rayOrigin = (target * CFrame.new(0, rayLength, 0)).Position
    local rayDir = (target.Position - rayOrigin).Unit

    return workspace:Raycast(rayOrigin, rayDir * rayLength * 2, raycastParams)
end

return GridUtil