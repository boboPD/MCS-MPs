using System;
using System.Collections.Generic;
using System.IO;
class Solution
{

    static byte[,] trainingData, testData;
    static byte[] label;

    class Node
    {
        int attr;
        Dictionary<byte, Node> children;

        bool isLeaf = false;
        byte leafVal;

        public void AddSubtree(int attrValue, Node subtree)
        {
            children.Add(attrValue, subtree);
        }
    }



    static void Main(String[] args)
    {
        ReadTrainingData();
    }

    private static void ReadTrainingData()
    {
        int numberOfLines = int.Parse(Console.ReadLine());
        string[] line = Console.ReadLine().Split(" ");
        int numberOfAttrs = line.Length - 1;

        trainingData = new byte[numberOfLines, numberOfAttrs];
        label = new byte[numberOfLines];

        for (int i = 1; i < numberOfLines; i++)
        {
            label[i] = byte.Parse(line[0]);
            for (int j = 1; j < line.Length; j++)
            {
                byte val = byte.Parse(line[j].Split(":")[1]);
                trainingData[i, j - 1] = val;
            }
            line = Console.ReadLine().Split(" ");
        }
    }

    private static void ReadTestData()
    {
        int numberOfLines = int.Parse(Console.ReadLine());
        string[] line = Console.ReadLine().Split(" ");
        int numberOfAttrs = line.Length;

        var data = new byte[numberOfLines, numberOfAttrs];

        for (int i = 1; i < numberOfLines; i++)
        {
            for (int j = 0; j < line.Length; j++)
            {
                byte val = byte.Parse(line[j].Split(":")[1]);
                testData[i, j] = val;
            }
            line = Console.ReadLine().Split(" ");
        }
    }

    private Node TrainDecisionTree(Node root, int[] relevantRows, int[] attrs)
    {
    }

    private int SelectSplitAttr(IEnumerable relevantRows, IEnumerable attrs)
    {
        var cntByAttrValAndLabel = new Dictionary<byte, Dictionary<byte, int>>();
        var labelTotalCount = new Dictionary<byte, int>();
        double minGini = double.MaxValue, currGini;
        int selectedAttr;

        foreach (int attr in attrs)
        {
            foreach (int idx in relevantRows)
            {
                if (!cntByAttrValAndLabel.ContainsKey(trainingData[idx, attr]))
                {
                    cntByAttrValAndLabel.Add(trainingData[idx, attr], new Dictionary<byte, int>());
                    cntByAttrValAndLabel[trainingData[idx, attr]].Add(label[idx], 1);
                    labelTotalCount.Add(trainingData[idx, attr], 1);
                }
                else
                {
                    ++cntByAttrValAndLabel[trainingData[idx, attr]][label[idx]];
                    ++labelTotalCount(trainingData[idx, attr]);
                }
            }

            foreach (byte attrVal in cntByAttrValAndLabel.Keys)
            {
                double prob = 0.0d;
                foreach (byte labelVal in cntByAttrValAndLabel[attrVal])
                {
                    prob += Math.Pow((double)cntByAttrValAndLabel[attrVal][labelVal] / labelTotalCount[attrVal], 2.0);
                }

                currGini = (labelTotalCount[attrVal]/(double)relevantRows.Length) * (1 - prob);
                if(currGini < minGini)
                {
                    minGini = currGini;
                    selectedAttr = attr;
                }
            }
        }

        return selectedAttr;
    }
}