def model(req):
    if req == 0:
        return 0,0
    for i in range(7,-1,-1):
        if (req>>i)&1:
            return i,1
    raise AssertionError

def run():
    for req in range(256):
        idx,valid=model(req)
        assert valid == int(req!=0)
        if valid:
            assert (req>>idx)&1
            assert (req >> (idx+1)) == 0
    assert model(0)==(0,0)
    assert model(1)==(0,1)
    assert model(0x80)==(7,1)
    assert model(0x28)==(5,1)
    print("A04 independent Python model: PASS")

if __name__=="__main__":
    run()
