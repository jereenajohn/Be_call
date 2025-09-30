import 'package:be_call/countries_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_state_cubit.dart';

class AddstateFormPage extends StatefulWidget {
  const AddstateFormPage({super.key});

  @override
  State<AddstateFormPage> createState() => _AddstateFormPageState();
}
class _AddstateFormPageState extends State<AddstateFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _stateCtrl = TextEditingController();
  final Color accent = const Color.fromARGB(255, 26, 164, 143);

  int? _selectedCountryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Add state'),
        backgroundColor: Colors.black,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<AddStateCubit, AddStateState>(
                listener: (context, state) {
                  if (state is AddStateSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: accent),
                    );
                    _formKey.currentState?.reset();
                    _stateCtrl.clear();
                    _selectedCountryId = null;
                  } else if (state is AddStateError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.error), backgroundColor: Colors.red),
                    );
                  }
                },
                builder: (context, addState) {
                  return Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        // Country Dropdown
                        BlocBuilder<CountriesCubit, CountriesState>(
                          builder: (context, cState) {
                            if (cState is CountriesLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (cState is CountriesLoaded) {
                              return DropdownButtonFormField<int>(
                                value: _selectedCountryId,
                                decoration: InputDecoration(
                                  labelText: "Country",
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  filled: true,
                                  fillColor: Colors.grey[900],
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                dropdownColor: Colors.grey[900],
                                iconEnabledColor: Colors.white,
                                style: const TextStyle(color: Colors.white),
                                items: cState.countries.map((c) {
                                  return DropdownMenuItem<int>(
                                    value: c['id'],
                                    child: Text(c['name']),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedCountryId = v),
                                validator: (v) =>
                                    v == null ? 'Select a country' : null,
                              );
                            } else if (cState is CountriesError) {
                              return Text(
                                'Error: ${cState.error}',
                                style: const TextStyle(color: Colors.red),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        const SizedBox(height: 20),

                        // State name input
                        TextFormField(
                          controller: _stateCtrl,
                          decoration: InputDecoration(
                            labelText: "State Name",
                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          validator: (v) => v!.isEmpty ? 'Enter State name' : null,
                          style: const TextStyle(color: Colors.white),
                        ),

                        const SizedBox(height: 28),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: addState is AddStateLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AddStateCubit>().saveState(
                                      _stateCtrl.text,
                                      _selectedCountryId,
                                      // If you want to send the country id to your API,
                                      // extend saveState to accept _selectedCountryId
                                    );
                                  }
                                },
                          child: addState is AddStateLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
