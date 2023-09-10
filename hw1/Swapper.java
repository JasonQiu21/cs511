public class Swapper implements Runnable {
    private int offset;
    private Interval interval;
    private String content;
    private char[] buffer;

    public Swapper(Interval interval, String content, char[] buffer, int offset) {
        this.offset = offset;
        this.interval = interval;
        this.content = content;
        this.buffer = buffer;
    }

    @Override
    public void run() {
        // TODO: Implement me!
        // System.out.printf("interval: %d, %d\noffset: %d\n", interval.getX(), interval.getY(), offset);
        for(int i = this.interval.getX(); i < this.interval.getY(); i++){
            this.buffer[offset + i - this.interval.getX()] = this.content.charAt(i);
        }
    }
}