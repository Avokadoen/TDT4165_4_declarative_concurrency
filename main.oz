functor

import
    Application(exit:Exit)
    System
    OS
define
    {System.showInfo 'Task 1'}
    fun {GenerateOdd Start End}
        if Start > End then 
            nil
        else
            if Start mod 2 == 1 then
                local
                    NewValue = Start + 2
                in
                    Start|{GenerateOdd NewValue End}
                end
            else
                local
                    NewValue = Start + 1
                in
                    {GenerateOdd NewValue End}
                end
            end
        end
    end

    % Prints: [~3 ~1 1 3 5 7]
    {System.showInfo 'Running {GenerateOdd ~3 10} ...'}
    {System.show {GenerateOdd ~3 10}}
    
    % Prints: [3]
    {System.showInfo '\nRunning {GenerateOdd 3 3} ...'}
    {System.show {GenerateOdd 3 3}}

    % Prints: nil
    {System.showInfo '\nRunning {GenerateOdd 2 2} ...'}
    {System.show {GenerateOdd 2 2}}
    % END OF TASK 1 ----------------------------------------------


    {System.showInfo '\n\nTask 2'}
    fun {Product L} 
        case L of Head|Tail then
            Head * {Product Tail}
        else
            1
        end
    end
    % Prints: 24
    {System.showInfo 'running {Product [1 2 3 4]} ...'}
    {System.show {Product [1 2 3 4]}}
    % END OF TASK 2 ----------------------------------------------


    {System.showInfo '\n\nTask 3'}
    {System.showInfo 'Running example, please read source code comments ...'}
    local 
        X
        Y

        fun {Consume L} 
            case L of Head|Tail then
                Head * 2 | Tail
            else 
                nil
            end
        end
    in
        thread X = {GenerateOdd 0 1000} end
        thread 
            Y = {Consume X}
            {System.showInfo Y.1}
            {System.showInfo Y.2.1}
            {System.showInfo Y.2.2.1}

            % Since we produce and consume in two different threads, OZ can use the fact that X is a stream
            % to read values from it before the whole dataset is computated. This means that one core on the CPU
            % can perform our multiplication while another core is still generating odd numbers. There is some
            % scheduling happening behind the scenes by Oz to make this safe of course.
            
            % So to summerize. Instead of our program running like this:
            % Produce: ------------              *~1000*
            % Consume:             ------------- *~2000*
            % Time     ------------------------- *~2000*
            
            % Oz can make it run like this:
            % Produce: --- -- ------  *~1000*
            % Consume:   --- -------- *~1000*
            % Time     -------------- *~1000*
        end

        % Suspend main thread until Y is assigned
        {Wait Y}
    end
    % END OF TASK 3 ----------------------------------------------


    {System.showInfo '\n\nTask 4'}
    local 
        X
        Y
        % Copy GenerateOdd with lazy annotation
        fun lazy {GenerateOddLazy Start End}
            if Start > End then 
                nil
            else
                if Start mod 2 == 1 then
                    local
                        NewValue = Start + 2
                    in
                        Start|{GenerateOddLazy NewValue End}
                    end
                else
                    local
                        NewValue = Start + 1
                    in
                        {GenerateOddLazy NewValue End}
                    end
                end
            end
        end
    in
        % Example to showcase how lazy enables us to generate towards infinity
        {System.showInfo '\nRunning X = {GenerateOddLazy 0 9999999999999999}'}
        thread X = {GenerateOddLazy 0 9999999999999999} end
        thread
            {System.showInfo '\nReading X in another thread'}
            {System.showInfo 'X.1:\t\t'#X.1}
            {System.showInfo 'X.2.1:\t\t'#X.2.1}
            {System.showInfo 'X.2.2.1:\t'#X.2.2.1}
            Y = X
        end

        {Wait Y} % Use Y to control execution of prints and stop program from executing the next task
        {System.showInfo '\nLeaving X scope which will exit generate thread'}
    end

    % Here we change our producer to be 'lazy' annotated. This makes the program change its behaviour
    % To only run a new recursive call if needed. In other languages this usually done by using 'generators'
    % Which are a special type of function with a state. They also often use the term 'yield' instead of return when 
    % they complete one computation. Generators are a subset of Coroutines. The main differenece between the two 
    % is the level of control of entry points. Coroutines can have multiple entry points on repeated entry, Generators
    % can not. 
    % Sources:
    % https://en.wikipedia.org/wiki/Generator_(computer_programming)
    % https://en.wikipedia.org/wiki/Coroutine

    % So to summarize: 
    % Instead of our previous execution that looked somewhat like this:
    % Oz can make it run like this:
    % Produce: --- -- ------  *~1000*
    % Consume:   --- -------- *~1000*
    % Time     -------------- *~1000* 
    
    % Our exection looks more like this
    % Produce: ---   *~4*    
    % Consume:   --- *~4*
    % Time     ----- *~4*
    % Caused by us only using 3 'products' 
    % END OF TASK 4 ----------------------------------------------


    {System.showInfo '\n\nTask 5'}

    % Copy paste from task description
    % Creates a random number from Min (Inclusive) to Max (Inclusive)
    fun {RandomInt Min Max}
        X = {OS.rand}
        MinOS
        MaxOS
    in
        {OS.randLimits ?MinOS ?MaxOS} Min + X * (Max - Min) div (MaxOS - MinOS)
    end
    {System.showInfo '\na) Making 4 hammers. Please wait ...'}

    % Creates a hammer after ~1 second (In practice, a bit longer than 1 second)
    fun lazy {HammerFactory} 
        Quality = {RandomInt 1 10}
    in
        {Time.delay 1000} 
        if Quality == 1 then
            defect|{HammerFactory}
        else 
            working|{HammerFactory}
        end
    end

    % Test {HammerFactory}
    local 
        HammerTime 
        B 
    in
        HammerTime = {HammerFactory}
        B = HammerTime.2.2.2.1 % force production of 4 hammers
        {System.show HammerTime}
    end
 
    {Exit 0}
end
