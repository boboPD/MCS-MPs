class ItemSet:
    def __init__(self, items_list):
        self.items = items_list
    
    def __hash__(self):
        h = 1
        for i in self.items:
            h = h * hash(i)
        
        return h
    
    def __eq__(self, other):
        l_a = len(self.items)
        l_b = len(other.items)

        if l_a != l_b:
            return False

        s_a = sorted(self.items)
        s_b = sorted(other.items)

        for i in range(l_a):
            if s_a[i] != s_b[i]:
                return False

        return True
    
    def __str__(self):
        return ";".join(self.items)