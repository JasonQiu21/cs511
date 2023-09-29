// Jason Qiu
// I pledge my honor that I have abided by the Stevens Honor System.

import java.util.Arrays;
import java.util.List;
import java.util.ArrayList; // Need to import ArrayList to instantiate shoppingCart
import java.util.Random;
import java.util.concurrent.CountDownLatch;

public class Customer implements Runnable {
    private Bakery bakery;
    private Random rnd;
    private List<BreadType> shoppingCart;
    private int shopTime;
    private int checkoutTime;
    private CountDownLatch doneSignal;
    
    /**
     * Initialize a customer object and randomize its shopping cart
     */
    public Customer(Bakery bakery, CountDownLatch l) {
        rnd = new Random(1257);
        shopTime = rnd.nextInt(500);
        checkoutTime = rnd.nextInt(500);
        doneSignal = l;
        this.bakery = bakery;
        shoppingCart = new ArrayList<BreadType>();
        fillShoppingCart();
    }

    /**
     * Run tasks for the customer
     */
    public void run() {
        System.out.println(hashCode() + ": Begin shopping");
        for(BreadType i: shoppingCart){
            try{
                bakery.shelves.get(i).acquire();
                System.out.println(hashCode() + ": Getting " + i.toString() + " bread...");
                Thread.sleep(shopTime);
                bakery.takeBread(i);
                bakery.shelves.get(i).release();
            } catch (InterruptedException ie){
                ie.printStackTrace();
            }
        }
        System.out.println(hashCode() + ": Done shopping. Begin checkout");
        getItemsValue();

        try{
            bakery.cashiers.acquire();
            System.out.println(hashCode() + ": Checking out");
            Thread.sleep(checkoutTime);
            bakery.cashiers.release();

            bakery.salesSemaphore.acquire();
            bakery.addSales(getItemsValue());
            bakery.salesSemaphore.release();
        } catch (InterruptedException ie){
            ie.printStackTrace();
        }
        System.out.println(hashCode() + ": Done checkout; leaving store.");
        doneSignal.countDown();
            
    }

    /**
     * Return a string representation of the customer
     */
    public String toString() {
        return "Customer " + hashCode() + ": shoppingCart=" + Arrays.toString(shoppingCart.toArray()) + ", shopTime=" + shopTime + ", checkoutTime=" + checkoutTime;
    }

    /**
     * Add a bread item to the customer's shopping cart
     */
    private boolean addItem(BreadType bread) {
        // do not allow more than 3 items, chooseItems() does not call more than 3 times
        if (shoppingCart.size() >= 3) {
            return false;
        }
        shoppingCart.add(bread);
        return true;
    }

    /**
     * Fill the customer's shopping cart with 1 to 3 random breads
     */
    private void fillShoppingCart() {
        int itemCnt = 1 + rnd.nextInt(3);
        while (itemCnt > 0) {
            addItem(BreadType.values()[rnd.nextInt(BreadType.values().length)]);
            itemCnt--;
        }
    }

    /**
     * Calculate the total value of the items in the customer's shopping cart
     */
    private float getItemsValue() {
        float value = 0;
        for (BreadType bread : shoppingCart) {
            value += bread.getPrice();
        }
        return value;
    }
}
