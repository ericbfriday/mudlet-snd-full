-- Test Phase 2 components
require("core")
require("database")
require("mock_data")

print("=== Testing Phase 2 Components ===")

-- Test database initialization
print("1. Testing database initialization...")
SnD.Database.init()
print("   ✓ Database initialized")

-- Test mock data
print("2. Testing mock data...")
SnD.Mock.enable()
print("   ✓ Mock data enabled")

-- Test GMCP simulation
print("3. Testing GMCP simulation...")
if gmcp and gmcp.room and gmcp.room.info then
    print("   ✓ GMCP room data available:", gmcp.room.info.name)
else
    print("   ✗ GMCP room data not available")
end

if gmcp and gmcp.comm and gmcp.comm.quest then
    print("   ✓ GMCP quest data available")
else
    print("   ✗ GMCP quest data not available")
end

print("=== Phase 2 Test Complete ===")