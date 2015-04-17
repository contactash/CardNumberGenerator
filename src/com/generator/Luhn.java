package com.generator;

import org.junit.Test;
import java.util.ArrayList;
import java.util.List;
import static org.hamcrest.MatcherAssert.*;
import static org.hamcrest.Matchers.*;

public class Luhn {
    public static boolean Check(String ccNumber)  {
        int sum = 0;
        boolean alternate = false;
        for (int i = ccNumber.length() - 1; i >= 0; i--)  {
            int n = Integer.parseInt(ccNumber.substring(i, i + 1));
            if (alternate)
            {
                n *= 2;
                if (n > 9)
                {
                    n = (n % 10) + 1;
                }
            }
            sum += n;
            alternate = !alternate;
        }
        return (sum % 10 == 0);
    }

    @Test
    public void luhnTest() throws Exception {
        List<Boolean> values= new ArrayList<Boolean>();
        values.add(new Boolean(true));
        values.add(new Boolean(false));
        assertThat(Luhn.Check("4111111111111111"), isA(Boolean.class));
        assertThat(Luhn.Check("44444444444444444"),isIn(values));
        assertThat(Luhn.Check("2323232323232"),instanceOf(boolean.class));
        assertThat(Luhn.Check("23232323232"),not(true));
        assertThat(Luhn.Check("123123123123"),is(false));

    }

}