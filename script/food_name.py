import json
import csv

# 1. 假设你的 JSON 文件名为 ingredients.json
input_filename = 'list.php.json'
output_filename = 'ingredients_list.csv'

try:
    # 2. 读取 JSON 文件
    with open(input_filename, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 3. 提取所有的 strIngredient
    # data['meals'] 是一个列表，我们遍历它并获取 strIngredient 字段
    ingredients = [item['strIngredient'] for item in data.get('meals', []) if item.get('strIngredient')]

    # 4. 保存到 CSV 文件
    with open(output_filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)

        # 写入表头 (可选)
        writer.writerow(['IngredientName'])

        # 写入每一行数据
        for name in ingredients:
            writer.writerow([name])

    print(f"提取完成！共计 {len(ingredients)} 条食材已保存至 {output_filename}")

except FileNotFoundError:
    print(f"错误：找不到文件 {input_filename}")
except json.JSONDecodeError:
    print("错误：JSON 文件格式不正确")
except Exception as e:
    print(f"发生未知错误: {e}")