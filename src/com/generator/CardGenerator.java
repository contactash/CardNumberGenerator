package com.generator;

import org.junit.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;



public class CardGenerator {
    String rangeStart, rangeEnd;
    String panStart = "0000";
    String panEnd = "9999";
    List<String> validCards;

    public void validCardNumbers(String rangeStart, String rangeEnd) {
        this.rangeStart = rangeStart;
        this.rangeEnd = rangeEnd;
        validCards = new ArrayList<String>();
        rangeStart = rangeStart + panStart;
        rangeEnd = rangeEnd + panEnd;
        for (Long i = Long.parseLong(rangeStart); i < Long.parseLong(rangeEnd.trim()); i++) {
            if (Luhn.Check(String.valueOf(i))) {
                validCards.add(String.valueOf(i));
            }
        }
        printValidCards(validCards);
    }

    public void printValidCards(List<String> cardNumbers) {
        Random r = new Random();
        for (int i = 0; i < 10; i++) {
            int k = r.nextInt(1000) + 1;
            System.out.print(cardNumbers.get(k) + ",");
        }
        System.out.println();
/*       for(String s:cardNumbers)
      {
         System.out.println(s);
      } */
    }

    @Test
    public void CardTest() {
        validCardNumbers("611111111111", "611111111119");
        validCardNumbers("417418002811", "417418002900");
    }
}

