import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCompletionPage extends StatefulWidget {
  final String name;
  final String email;

  const ProfileCompletionPage({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final ageController = TextEditingController();
  String? selectedObjective;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complétez votre profil")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              Text(
                "Bienvenue ${widget.name} 👋",
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Poids",
                  suffixText: "kg",
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Poids requis";
                  final w = double.tryParse(v);
                  return (w == null) ? "Entrez un nombre valide" : null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Taille",
                  suffixText: "cm",
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Taille requise";
                  final h = double.tryParse(v);
                  return (h == null) ? "Entrez un nombre valide" : null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Âge (optionnel)",
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: selectedObjective,
                decoration: const InputDecoration(
                  labelText: "Objectif sportif",
                ),
                items: const [
                  DropdownMenuItem(
                    value: "lose_weight",
                    child: Text("Perdre du poids"),
                  ),
                  DropdownMenuItem(
                    value: "build_muscle",
                    child: Text("Prendre du muscle"),
                  ),
                  DropdownMenuItem(
                    value: "maintain",
                    child: Text("Maintenir"),
                  ),
                ],
                onChanged: (value) {
                  setState(() => selectedObjective = value);
                },
                validator: (v) =>
                v == null ? "Sélectionnez un objectif" : null,
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;

                  // TODO: Envoyer les données au backend

                  Get.snackbar(
                    "Profil complété",
                    "Vos informations ont été sauvegardées",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: const Text("Continuer"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
