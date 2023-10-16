// Jason Qiu and Jackey Yang
// I pledge my honor that I have abided by the Stevens Honor System.

class GS {
    int g
    GS(){
        g = 0
    }

    synchronized void start_gasUp(){
        while(g >= 6){
            wait()
        }
        g++
        System.out.println("Getting gas...")
    }
    synchronized void done_gasUp(){
        g--
        notifyAll()
        System.out.println("Done getting gas")
    }
    synchronized void start_refuel(){
        while(g != 0){
            wait()
        }
        g = 6
        System.out.println("Refuelling...")
    }
    synchronized void done_refuel(){
        g = 0
        notifyAll()
        System.out.println("Done refuelling")
    }
}

GS gs = new GS()
final int NV = 100
final int   NT = 10

NV.times{
    Thread.start{
        gs.start_gasUp()

        gs.done_gasUp()
    }
}

NT.times{
    Thread.start{
        gs.start_refuel()

        gs.done_refuel()
    }
}