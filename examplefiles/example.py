def rst_test(a):
    """This should be shown in rst formatting

    Args:
        a: The paramater

    Example:
        This is how you can use this function:

        .. code-block:: python

            result = test(3)
            print(result)
    """
    testcss = "background-color: pink"
    testhtml = "<p>very great css</p>"
    testjs = "const x=5"
    return [testcss, testhtml, testjs]
